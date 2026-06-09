import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../../database/btk_database.dart';
import '../../../models/gps_track.dart';

class GpsTrackNotifier extends StateNotifier<GpsTrack?> {
  StreamSubscription<Position>? _sub;

  GpsTrackNotifier() : super(null);

  bool get isTracking => state != null && state!.endedAt == null;

  Future<void> startTracking() async {
    if (isTracking) return;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }

    final track = GpsTrack(
      id: const Uuid().v4().substring(0, 8),
      startedAt: DateTime.now(),
    );
    state = track;
    await BtkDatabase.insertTrack(track);

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) async {
      if (state == null || state!.endedAt != null) return;
      final point = GpsPoint(
        lat: pos.latitude,
        lon: pos.longitude,
        altitude: pos.altitude,
        time: pos.timestamp,
      );
      final updated = state!.copyWith(points: [...state!.points, point]);
      state = updated;
      await BtkDatabase.updateTrack(updated);
    });
  }

  Future<GpsTrack?> stopTracking() async {
    if (!isTracking) return null;
    await _sub?.cancel();
    _sub = null;
    final finished = state!.copyWith(endedAt: DateTime.now());
    state = finished;
    await BtkDatabase.updateTrack(finished);
    return finished;
  }

  void clearTrack() => state = null;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final gpsTrackProvider =
    StateNotifierProvider<GpsTrackNotifier, GpsTrack?>(
  (ref) => GpsTrackNotifier(),
);
