import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../database/btk_database.dart';
import '../../models/btk_record.dart';

/// A version of a record that another write replaced, kept until someone decides
/// what to do with it.
class KeptVersion {
  final String id;
  final BtkRecord record;
  final DateTime keptAt;

  const KeptVersion(this.id, this.record, this.keptAt);
}

/// On-device storage for sync safety. It lives outside Firestore's cache so that
/// a version stays here after the server has replaced it. A [scope] names one
/// shared space: an account's records or one expedition's.
abstract class ConflictStore {
  static ConflictStore instance = kIsWeb ? WebConflictStore() : SqliteConflictStore();

  final _changes = StreamController<void>.broadcast();

  /// Fires when the list of kept versions changes.
  Stream<void> get changes => _changes.stream;

  void notifyChanged() => _changes.add(null);

  /// This device's own unconfirmed saves, by record ID.
  Future<Map<String, BtkRecord>> lastWrites(String scope);
  Future<void> setLastWrite(String scope, BtkRecord record);
  Future<void> forgetLastWrite(String scope, String recordId);

  Future<List<KeptVersion>> kept(String scope);
  Future<void> addKept(String scope, BtkRecord record);
  Future<void> removeKept(String id);
}

class SqliteConflictStore extends ConflictStore {
  @override
  Future<Map<String, BtkRecord>> lastWrites(String scope) async {
    final db = await BtkDatabase.database;
    final rows = await db.query('sync_last_writes', where: 'scope = ?', whereArgs: [scope]);
    return {
      for (final row in rows)
        row['record_id'] as String:
            BtkRecord.fromJson(jsonDecode(row['json'] as String) as Map<String, dynamic>),
    };
  }

  @override
  Future<void> setLastWrite(String scope, BtkRecord record) async {
    final db = await BtkDatabase.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO sync_last_writes (scope, record_id, json) VALUES (?, ?, ?)',
      [scope, record.id, jsonEncode(record.toJson())],
    );
  }

  @override
  Future<void> forgetLastWrite(String scope, String recordId) async {
    final db = await BtkDatabase.database;
    await db.delete('sync_last_writes',
        where: 'scope = ? AND record_id = ?', whereArgs: [scope, recordId]);
  }

  @override
  Future<List<KeptVersion>> kept(String scope) async {
    final db = await BtkDatabase.database;
    final rows = await db.query('sync_kept_versions',
        where: 'scope = ?', whereArgs: [scope], orderBy: 'kept_at DESC');
    return [
      for (final row in rows)
        KeptVersion(
          row['id'] as String,
          BtkRecord.fromJson(jsonDecode(row['json'] as String) as Map<String, dynamic>),
          DateTime.parse(row['kept_at'] as String),
        ),
    ];
  }

  @override
  Future<void> addKept(String scope, BtkRecord record) async {
    final db = await BtkDatabase.database;
    await db.insert('sync_kept_versions', {
      'id': const Uuid().v4(),
      'scope': scope,
      'record_id': record.id,
      'json': jsonEncode(record.toJson()),
      'kept_at': DateTime.now().toIso8601String(),
    });
    notifyChanged();
  }

  @override
  Future<void> removeKept(String id) async {
    final db = await BtkDatabase.database;
    await db.delete('sync_kept_versions', where: 'id = ?', whereArgs: [id]);
    notifyChanged();
  }
}

/// Web has no database, so this keeps one JSON document in SharedPreferences.
class WebConflictStore extends ConflictStore {
  static const _key = 'sync_store';

  Future<Map<String, dynamic>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return raw == null
        ? {'writes': <String, dynamic>{}, 'kept': <dynamic>[]}
        : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _write(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  // Each change rewrites the whole document, so changes must not overlap.
  Future<void> _queue = Future.value();

  Future<void> _change(void Function(Map<String, dynamic>) change) {
    final result = _queue.then((_) async {
      final data = await _read();
      change(data);
      await _write(data);
    });
    _queue = result.catchError((Object _) {});
    return result;
  }

  @override
  Future<Map<String, BtkRecord>> lastWrites(String scope) async {
    await _queue;
    final writes = ((await _read())['writes'] as Map)[scope] as Map? ?? const {};
    return {
      for (final e in writes.entries)
        e.key as String: BtkRecord.fromJson(Map<String, dynamic>.from(e.value as Map)),
    };
  }

  @override
  Future<void> setLastWrite(String scope, BtkRecord record) => _change((data) {
        final writes = data['writes'] as Map;
        (writes[scope] ??= <String, dynamic>{})[record.id] = record.toJson();
      });

  @override
  Future<void> forgetLastWrite(String scope, String recordId) => _change((data) {
        ((data['writes'] as Map)[scope] as Map?)?.remove(recordId);
      });

  @override
  Future<List<KeptVersion>> kept(String scope) async {
    await _queue;
    return [
      for (final item in (await _read())['kept'] as List)
        if (item['scope'] == scope)
          KeptVersion(
            item['id'] as String,
            BtkRecord.fromJson(Map<String, dynamic>.from(item['json'] as Map)),
            DateTime.parse(item['keptAt'] as String),
          ),
    ]..sort((a, b) => b.keptAt.compareTo(a.keptAt));
  }

  @override
  Future<void> addKept(String scope, BtkRecord record) async {
    await _change((data) => (data['kept'] as List).add({
          'id': const Uuid().v4(),
          'scope': scope,
          'json': record.toJson(),
          'keptAt': DateTime.now().toIso8601String(),
        }));
    notifyChanged();
  }

  @override
  Future<void> removeKept(String id) async {
    await _change((data) => (data['kept'] as List).removeWhere((item) => item['id'] == id));
    notifyChanged();
  }
}
