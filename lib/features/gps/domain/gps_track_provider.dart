import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../../core/app_messenger.dart';
import '../../../database/btk_database.dart';
import '../../../models/gps_track.dart';

enum GpsSignal { waiting, ok, lost }

class GpsStatus {
  final GpsSignal signal;

  /// Accuracy of the latest fix in metres.
  final double? accuracy;

  const GpsStatus(this.signal, [this.accuracy]);
}

class GpsTrackNotifier extends StateNotifier<GpsTrack?> {
  GpsTrackNotifier(
    this._onStatus, {
    Stream<Position> Function(LocationSettings)? positions,
    Duration retryAfter = const Duration(seconds: 15),
  })  : _positions = positions ??
            ((s) => Geolocator.getPositionStream(locationSettings: s)),
        _retryAfter = retryAfter,
        super(null);

  final void Function(GpsStatus) _onStatus;
  final Stream<Position> Function(LocationSettings) _positions;
  final Duration _retryAfter;

  StreamSubscription<Position>? _sub;
  Timer? _retry;
  LocationSettings? _settings;

  // Points not yet in the database. Writes run one at a time, in order.
  final List<GpsPoint> _unsaved = [];
  Future<void> _writes = Future.value();
  bool _failureShown = false;

  bool get isTracking => state != null && state!.endedAt == null;

  /// Throws if the track can't be created. The caller checks location access.
  Future<void> startTracking(LocationSettings settings) async {
    if (isTracking) return;
    final track = GpsTrack(
      id: const Uuid().v4().substring(0, 8),
      startedAt: DateTime.now(),
    );
    await BtkDatabase.insertTrack(track);
    _begin(track, settings);
  }

  /// Carries on recording an interrupted track.
  void resume(GpsTrack track, LocationSettings settings) {
    if (!isTracking) _begin(track, settings);
  }

  void _begin(GpsTrack track, LocationSettings settings) {
    state = track;
    _settings = settings;
    _onStatus(const GpsStatus(GpsSignal.waiting));
    _subscribe();
  }

  void _subscribe() {
    _sub = _positions(_settings!).listen(
      _onPosition,
      onError: (Object _) => _onLost(),
      onDone: _onLost,
    );
  }

  void _onPosition(Position pos) {
    if (!isTracking) return;
    _retry?.cancel();
    final point = GpsPoint(
      lat: pos.latitude,
      lon: pos.longitude,
      altitude: pos.altitude,
      time: pos.timestamp,
      accuracy: pos.accuracy,
    );
    state = state!.copyWith(points: [...state!.points, point]);
    _onStatus(GpsStatus(GpsSignal.ok, pos.accuracy));
    _unsaved.add(point);
    _writes = _writes.then((_) => _writeUnsaved());
  }

  // Losing the signal must not end recording: everything received is already
  // saved, and new points join the same track once the signal is back.
  void _onLost() {
    if (!isTracking) return;
    _onStatus(const GpsStatus(GpsSignal.lost));
    _retry?.cancel();
    _retry = Timer(_retryAfter, _reconnect);
  }

  void _reconnect() {
    if (!isTracking) return;
    // Android doesn't let a foreground service start from the background.
    final app = WidgetsBinding.instance.lifecycleState;
    if (app != null && app != AppLifecycleState.resumed) {
      _retry = Timer(_retryAfter, _reconnect);
      return;
    }
    _sub?.cancel();
    _subscribe();
  }

  Future<void> _writeUnsaved() async {
    if (_unsaved.isEmpty || state == null) return;
    final batch = List.of(_unsaved);
    try {
      await BtkDatabase.appendTrackPoints(state!.id, batch);
      _unsaved.removeRange(0, batch.length);
      _failureShown = false;
    } catch (_) {
      // The points stay queued and go out with the next write.
      if (!_failureShown) {
        _failureShown = true;
        AppMessenger.showError((l10n) => l10n.trackSaveFailed);
      }
    }
  }

  Future<GpsTrack?> stopTracking() async {
    if (!isTracking) return null;
    _retry?.cancel();
    await _sub?.cancel();
    _sub = null;
    await _writes;
    await _writeUnsaved();
    final finished = state!.copyWith(endedAt: DateTime.now());
    if (_unsaved.isEmpty) {
      try {
        await BtkDatabase.finishTrack(finished.id, finished.endedAt!);
      } catch (_) {
        // It stays in the database as interrupted, with its points.
        AppMessenger.showError((l10n) => l10n.trackSaveFailed);
      }
    }
    _unsaved.clear();
    state = finished;
    return finished;
  }

  void clearTrack() => state = null;

  @override
  void dispose() {
    _retry?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}

/// A saved track being shown on the map.
final shownTrackProvider = StateProvider<GpsTrack?>((ref) => null);

final gpsStatusProvider =
    StateProvider<GpsStatus>((ref) => const GpsStatus(GpsSignal.waiting));

final gpsTrackProvider = StateNotifierProvider<GpsTrackNotifier, GpsTrack?>(
  (ref) => GpsTrackNotifier(
    (status) => ref.read(gpsStatusProvider.notifier).state = status,
  ),
);
