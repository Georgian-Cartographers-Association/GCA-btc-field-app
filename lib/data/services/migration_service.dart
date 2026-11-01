import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../database/btk_database.dart';
import '../../models/btk_record.dart';

/// One-time migration: SharedPreferences JSON → SQLite.
/// Safe to call on every cold start — runs until it succeeds (guarded by a flag).
class MigrationService {
  static const _migratedKey = 'sqlite_migrated_v1';

  static Future<void> migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) == true) return;

    final raw = prefs.getString(AppConstants.prefRecords);
    var failed = false;
    if (raw != null && raw.isNotEmpty && raw != '[]') {
      List<dynamic> list;
      try {
        list = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        // Corrupt prefs data can't be retried — don't block app start
        list = const [];
      }
      for (final item in list) {
        if (item is! Map) continue;
        try {
          // A retry must not replace a record edited since the first attempt.
          await BtkDatabase.insertRecordIfAbsent(
              BtkRecord.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          failed = true;
        }
      }
    }

    if (!failed) await prefs.setBool(_migratedKey, true);
    // SharedPreferences data is intentionally kept as a backup.
  }
}
