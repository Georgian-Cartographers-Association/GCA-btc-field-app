import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/record_template.dart';

/// Templates stay on the device and belong to no storage mode, so they work
/// offline and in every mode.
class TemplateService {
  TemplateService._();

  static const _key = 'record_templates';

  static Future<List<RecordTemplate>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final templates = <RecordTemplate>[];
    try {
      for (final item in jsonDecode(raw) as List) {
        try {
          templates.add(RecordTemplate.fromJson(Map<String, dynamic>.from(item as Map)));
        } catch (_) {
          // One damaged template must not hide the others.
        }
      }
    } catch (_) {
      return [];
    }
    return templates;
  }

  static Future<void> _write(List<RecordTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
        _key, jsonEncode(templates.map((t) => t.toJson()).toList()));
    if (!ok) throw StateError('Templates were not written');
  }

  static Future<void> add(RecordTemplate template) async =>
      _write([...await load(), template]);

  static Future<void> delete(String id) async =>
      _write((await load()).where((t) => t.id != id).toList());
}
