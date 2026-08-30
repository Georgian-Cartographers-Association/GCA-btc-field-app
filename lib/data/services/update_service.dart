import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const _prefKey = 'update_dismissed_v';
  static const _apiUrl = 'https://api.github.com/repos/'
      'Georgian-Cartographers-Association/GCA-btc-field-app/releases/latest';
  static bool _checked = false;

  static Future<void> checkAndNotify(BuildContext context) async {
    if (kIsWeb || _checked) return;
    _checked = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final prefs = await SharedPreferences.getInstance();
      final res = await http
          .get(Uri.parse(_apiUrl),
              headers: {'Accept': 'application/vnd.github.v3+json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (data['tag_name'] as String).replaceFirst('v', '');
      final url = data['html_url'] as String;
      if (!_isNewer(tag, info.version)) return;
      if (prefs.getString(_prefKey) == tag) return;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
        leading: const Icon(Icons.system_update_outlined),
        content: Text('ახალი ვერსია v$tag ხელმისაწვდომია'),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              prefs.setString(_prefKey, tag);
            },
            child: const Text('შემდეგ'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              prefs.setString(_prefKey, tag);
              await launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication);
            },
            child: const Text('ჩამოტვირთვა'),
          ),
        ],
      ));
    } catch (_) {}
  }

  static bool _isNewer(String remote, String current) {
    int seg(String v, int i) {
      final parts = v.split('.');
      return i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0;
    }
    for (int i = 0; i < 3; i++) {
      final r = seg(remote, i), c = seg(current, i);
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }
}
