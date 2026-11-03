// ════════════════════════════════════════════════════════════════════════════
// Generated / updated manually.
// Android section will be filled after running:
//   flutterfire configure --project=gca-btk-field-app
// ════════════════════════════════════════════════════════════════════════════

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions not configured for this platform. '
            'Run: flutterfire configure --project=gca-btk-field-app');
    }
  }

  // ── Web ───────────────────────────────────────────────────────────────────

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCmHZpaB60kGcMRqEzT6fqD4GxGpO01UJo',
    appId: '1:699141416460:web:274e0c5e564e8a4890f029',
    messagingSenderId: '699141416460',
    projectId: 'gca-btk-field-app',
    authDomain: 'gca-btk-field-app.firebaseapp.com',
    storageBucket: 'gca-btk-field-app.firebasestorage.app',
    measurementId: 'G-G15W816JJ5',
  );

  // ── Android ───────────────────────────────────────────────────────────────

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDyuQPzRoqSL9RnDT6r1b5jaq18EmH1eW0',
    appId: '1:699141416460:android:27d1fd597f130b4d90f029',
    messagingSenderId: '699141416460',
    projectId: 'gca-btk-field-app',
    storageBucket: 'gca-btk-field-app.firebasestorage.app',
  );

  // ── iOS ────────────────────────────────────────────────────────────────────

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAseACjupieAg0od4gdo7hiakZcIJaSuKg',
    appId: '1:699141416460:ios:82e8ab4f52e2dc5190f029',
    messagingSenderId: '699141416460',
    projectId: 'gca-btk-field-app',
    storageBucket: 'gca-btk-field-app.firebasestorage.app',
    iosBundleId: 'ge.btc.fieldApp',
  );
}
