import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_messenger.dart';
import '../../core/constants.dart';
import '../../database/btk_database.dart';
import '../../models/btk_record.dart';
import '../services/migration_service.dart';
import 'data_repository.dart';

/// Stores BTK records in SQLite (Android) or SharedPreferences (web).
class LocalRepository implements DataRepository {
  /// Local storage is one-shot — no live stream.
  @override
  Stream<List<BtkRecord>>? get stream => null;

  @override
  Future<List<BtkRecord>> getAll() async {
    final (records, skipped) =
        kIsWeb ? await _loadWeb() : await _loadDatabase();
    if (skipped > 0) {
      AppMessenger.showError((l10n) => l10n.recordsUnreadable(skipped));
    }
    return records;
  }

  static Future<(List<BtkRecord>, int)> _loadDatabase() async {
    await MigrationService.migrateIfNeeded();
    return BtkDatabase.readAllRecords();
  }

  @override
  Future<bool> upsert(BtkRecord record, {bool keepUpdatedAt = false}) async {
    if (!keepUpdatedAt) record.updatedAt = DateTime.now();
    if (kIsWeb) {
      await _serialWeb(() async {
        final (all, _) = await _loadWeb();
        final idx = all.indexWhere((r) => r.id == record.id);
        if (idx >= 0) {
          all[idx] = record;
        } else {
          all.add(record);
        }
        await _saveWeb(all);
      });
    } else {
      await BtkDatabase.upsertRecord(record);
    }
    return false;
  }

  @override
  Future<void> delete(String id) async {
    if (kIsWeb) {
      await _serialWeb(() async {
        final (all, _) = await _loadWeb();
        await _saveWeb(all.where((r) => r.id != id).toList());
      });
    } else {
      // Files go last, so a failed database delete leaves the photos intact.
      final photos = await BtkDatabase.getRecordPhotos(id);
      await BtkDatabase.deleteRecord(id);
      for (final photo in photos) {
        try {
          await File(photo.filePath).delete();
        } catch (_) {}
      }
    }
  }

  // ── Web helpers ─────────────────────────────────────────────────────────────

  // Each web save rewrites all records, so saves must not overlap.
  static Future<void> _webQueue = Future.value();

  static Future<void> _serialWeb(Future<void> Function() action) {
    final result = _webQueue.then((_) => action());
    _webQueue = result.catchError((Object _) {});
    return result;
  }

  static Future<(List<BtkRecord>, int)> _loadWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.prefRecords);
    if (raw == null) return (<BtkRecord>[], 0);
    final list = jsonDecode(raw) as List<dynamic>;
    final records = <BtkRecord>[];
    for (final item in list) {
      if (item is Map) {
        records.add(BtkRecord.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return (records, list.length - records.length);
  }

  static Future<void> _saveWeb(List<BtkRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefRecords,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }
}
