import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Settings for recording a track. On Android, the foreground service keeps
/// recording with the screen off. It starts while the app is open, so it needs
/// no background location permission.
LocationSettings trackLocationSettings({
  required String notificationTitle,
  required String notificationText,
}) {
  if (!_isAndroid) {
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
  }
  return AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
    useMSLAltitude: true,
    foregroundNotificationConfig: ForegroundNotificationConfig(
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      enableWakeLock: true,
      setOngoing: true,
    ),
  );
}

/// Waits for a first fix, then briefly for a better one: the first fix may come
/// before the receiver reports sea-level altitude, and is often the least
/// accurate. Throws if no fix arrives within [limit].
@visibleForTesting
Future<Position> settleFix(
  Stream<Position> positions, {
  Duration settle = const Duration(seconds: 3),
  Duration limit = const Duration(seconds: 30),
}) {
  final done = Completer<Position>();
  Position? latest;
  Timer? settleTimer;
  late final Timer limitTimer;
  late final StreamSubscription<Position> sub;

  void finish() {
    settleTimer?.cancel();
    limitTimer.cancel();
    sub.cancel();
    if (done.isCompleted) return;
    if (latest != null) {
      done.complete(latest!);
    } else {
      done.completeError(TimeoutException('No GPS fix', limit));
    }
  }

  limitTimer = Timer(limit, finish);
  sub = positions.listen(
    (p) {
      latest = p;
      settleTimer ??= Timer(settle, finish);
    },
    onError: (Object e) {
      // A later fix can still arrive, unless the stream has nothing yet and ends.
    },
    onDone: finish,
  );
  return done.future;
}

/// A fresh position for a record, with sea-level altitude where the phone gives it.
///
/// The plugin keeps one position stream per app and hands it to every caller.
/// While a track is [recording], that stream only moves every 10 m, so someone
/// standing still would never get a fix. A one-off request works, without the
/// sea-level altitude.
Future<Position> currentFix({required bool recording}) {
  if (_isAndroid && !recording) {
    return settleFix(Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.best,
        useMSLAltitude: true,
      ),
    ));
  }
  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      timeLimit: Duration(seconds: 30),
    ),
  );
}
