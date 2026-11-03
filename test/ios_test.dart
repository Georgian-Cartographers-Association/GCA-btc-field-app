import 'package:btk_field_app/core/app_paths.dart';
import 'dart:io';
import 'package:btk_field_app/features/gps/domain/location_settings.dart';
import 'package:btk_field_app/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

LocationSettings _settings() =>
    trackLocationSettings(notificationTitle: 't', notificationText: 'x');

void main() {
  group('Firebase', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('iOS uses its own app', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final options = DefaultFirebaseOptions.currentPlatform;
      expect(options.appId, contains(':ios:'));
      expect(options.projectId, DefaultFirebaseOptions.android.projectId);
    });

    test('the bundle ID matches the Xcode project', () {
      final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      expect(project,
          contains('PRODUCT_BUNDLE_IDENTIFIER = ${DefaultFirebaseOptions.ios.iosBundleId};'));
    });
  });

  group('saved paths', () {
    const docs = '/var/mobile/Containers/Data/Application/NEW/Documents';

    test('follow the app to its new container', () {
      expect(
        rebaseToDocuments(
            '/var/mobile/Containers/Data/Application/OLD/Documents/photos/r1/a.jpg', docs),
        '$docs/photos/r1/a.jpg',
      );
    });

    test('in the current container stay the same', () {
      expect(rebaseToDocuments('$docs/rasters/a.png', docs), '$docs/rasters/a.png');
    });

    test('outside Documents stay the same', () {
      expect(rebaseToDocuments('/tmp/a.jpg', docs), '/tmp/a.jpg');
    });

    test('are left alone on other platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(await documentsDirToRebase(), isNull);
    });
  });

  group('track recording', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('keeps going in the background on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final s = _settings() as AppleSettings;
      expect(s.allowBackgroundLocationUpdates, isTrue);
      expect(s.pauseLocationUpdatesAutomatically, isFalse);
      expect(s.showBackgroundLocationIndicator, isTrue);
    });

    test('still uses the foreground service on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final s = _settings() as AndroidSettings;
      expect(s.foregroundNotificationConfig, isNotNull);
    });
  });
}
