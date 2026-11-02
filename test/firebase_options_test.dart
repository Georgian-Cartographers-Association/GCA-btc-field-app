import 'dart:convert';
import 'dart:io';
import 'package:btk_field_app/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android uses the Firebase app registered for its own package', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final package = RegExp(r'applicationId = "([^"]+)"').firstMatch(gradle)!.group(1);

    final services = jsonDecode(File('android/app/google-services.json').readAsStringSync());
    final client = (services['client'] as List).firstWhere(
        (c) => c['client_info']['android_client_info']['package_name'] == package);

    expect(DefaultFirebaseOptions.android.appId, client['client_info']['mobilesdk_app_id']);
  });
}
