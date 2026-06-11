import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../database/btk_database.dart';
import '../../models/btk_record.dart';

/// One-time migration: SharedPreferences JSON → SQLite.
/// Safe to call on every cold start — runs only once (guarded by a flag).
class MigrationService {
  static const _migratedKey = 'sqlite_migrated_v1';

  static Future<void> migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) == true) return;

    final raw = prefs.getString(AppConstants.prefRecords);
    if (raw != null && raw.isNotEmpty && raw != '[]') {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          final r = BtkRecord.fromJson(item as Map<String, dynamic>);
          await BtkDatabase.upsertRecord(r);
        }
      } catch (_) {
        // Corrupt prefs data — skip migration, don't block app start
      }
    }

    await prefs.setBool(_migratedKey, true);
    // SharedPreferences data is intentionally kept as a backup.
  }
}
