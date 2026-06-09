import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../database/btk_database.dart';
import '../models/btk_record.dart';
import '../services/migration_service.dart';
import 'data_repository.dart';

/// Stores BTK records in SQLite (Android) or SharedPreferences (web).
class LocalRepository implements DataRepository {
  /// Local storage is one-shot — no live stream.
  @override
  Stream<List<BtkRecord>>? get stream => null;

  @override
  Future<List<BtkRecord>> getAll() async {
    if (kIsWeb) return _loadWeb();
    await MigrationService.migrateIfNeeded();
    return BtkDatabase.getAllRecords();
  }

  @override
  Future<bool> upsert(BtkRecord record) async {
    record.updatedAt = DateTime.now();
    if (kIsWeb) {
      final all = await _loadWeb();
      final idx = all.indexWhere((r) => r.id == record.id);
      if (idx >= 0) {
        all[idx] = record;
      } else {
        all.add(record);
      }
      await _saveWeb(all);
    } else {
      await BtkDatabase.upsertRecord(record);
    }
    return false;
  }

  @override
  Future<void> delete(String id) async {
    if (kIsWeb) {
      final all = await _loadWeb();
      await _saveWeb(all.where((r) => r.id != id).toList());
    } else {
      await _deletePhotoFiles(id);
      await BtkDatabase.deleteRecord(id);
    }
  }

  // Delete all photo files on disk for a record before removing from DB.
  static Future<void> _deletePhotoFiles(String id) async {
    final photos = await BtkDatabase.getPhotos(id);
    for (final photo in photos) {
      try {
        await File(photo.filePath).delete();
      } catch (_) {}
    }
  }

  // ── Web helpers ─────────────────────────────────────────────────────────────

  static Future<List<BtkRecord>> _loadWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.prefRecords);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => BtkRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> _saveWeb(List<BtkRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefRecords,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }
}
