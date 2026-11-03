import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/btk_record.dart';
import '../models/gps_track.dart';
import '../models/photo.dart';

/// SQLite wrapper — used on Android/desktop. Not available on web.
class BtkDatabase {
  static Database? _db;

  static Future<Database> get database async {
    assert(!kIsWeb, 'BtkDatabase is not available on web');
    _db ??= await _open(await _defaultPath());
    return _db!;
  }

  /// Opens the database at [dbPath] and makes it the active one.
  @visibleForTesting
  static Future<Database> openAt(String dbPath) async {
    await _db?.close();
    _db = await _open(dbPath);
    return _db!;
  }

  static Future<String> _defaultPath() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final dir = await getApplicationSupportDirectory();
      return join(dir.path, 'btk_field_app.db');
    }
    return join(await getDatabasesPath(), 'btk_field_app.db');
  }

  static Future<Database> _open(String dbPath) {
    return openDatabase(
      dbPath,
      version: 4,
      onCreate: (db, _) async {
        await _createV1(db);
        await _createV2(db);
        await _createV3(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createV2(db);
        if (oldVersion < 3) await _createV3(db);
        if (oldVersion < 4) await _repairV4(db);
      },
    );
  }

  static Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE btk_records (
        id          TEXT PRIMARY KEY,
        json        TEXT NOT NULL,
        date        TEXT NOT NULL,
        location    TEXT DEFAULT '',
        latitude    REAL,
        longitude   REAL,
        updated_at  TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE photos (
        id          TEXT PRIMARY KEY,
        record_id   TEXT NOT NULL,
        file_path   TEXT NOT NULL,
        caption     TEXT DEFAULT '',
        sort_order  INTEGER DEFAULT 0,
        created_at  TEXT NOT NULL,
        FOREIGN KEY (record_id) REFERENCES btk_records(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_records_date ON btk_records(date DESC)');
    await db.execute('CREATE INDEX idx_photos_record ON photos(record_id)');
  }

  static Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE gps_tracks (
        id          TEXT PRIMARY KEY,
        started_at  TEXT NOT NULL,
        ended_at    TEXT,
        points_json TEXT NOT NULL DEFAULT '[]'
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_tracks_started ON gps_tracks(started_at DESC)');
  }

  static Future<void> _createV3(Database db) async {
    await db.execute(
        "ALTER TABLE btk_records ADD COLUMN name TEXT DEFAULT ''");
  }

  // Databases created new at version 3 never ran _createV3, so `name` is missing.
  static Future<void> _repairV4(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(btk_records)');
    if (columns.any((c) => c['name'] == 'name')) return;
    await _createV3(db);
  }

  // ── BtkRecord ───────────────────────────────────────────────────────────────

  static Future<List<BtkRecord>> getAllRecords() async =>
      (await readAllRecords()).$1;

  /// Returns the records plus how many rows couldn't be read. Unreadable rows
  /// stay in the database, and don't stop the others from loading.
  static Future<(List<BtkRecord>, int)> readAllRecords() async {
    final db = await database;
    final rows = await db.query('btk_records', orderBy: 'date DESC');
    final records = <BtkRecord>[];
    var skipped = 0;
    for (final r in rows) {
      try {
        records.add(BtkRecord.fromStored(r['id'] as String,
            jsonDecode(r['json'] as String) as Map<String, dynamic>));
      } catch (_) {
        skipped++;
      }
    }
    return (records, skipped);
  }

  static Map<String, Object?> _recordRow(BtkRecord r) => {
        'id': r.id,
        'json': jsonEncode(r.toJson()),
        'date': r.date.toIso8601String(),
        'name': r.name,
        'location': r.location,
        'latitude': r.latitude,
        'longitude': r.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      };

  static Future<void> upsertRecord(BtkRecord r) async {
    final db = await database;
    await db.insert('btk_records', _recordRow(r),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> insertRecordIfAbsent(BtkRecord r) async {
    final db = await database;
    await db.insert('btk_records', _recordRow(r),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Deletes the record and the photo rows of all its sections.
  static Future<void> deleteRecord(String id) async {
    final db = await database;
    final keys = Photo.keysFor(id);
    await db.transaction((txn) async {
      await txn.delete('photos',
          where: 'record_id IN (${_marks(keys)})', whereArgs: keys);
      await txn.delete('btk_records', where: 'id = ?', whereArgs: [id]);
    });
  }

  static String _marks(List<String> values) =>
      List.filled(values.length, '?').join(',');

  // ── Photos ──────────────────────────────────────────────────────────────────

  /// All photos of a record, including the soil and vertical structure ones.
  static Future<List<Photo>> getRecordPhotos(String recordId) async {
    final db = await database;
    final keys = Photo.keysFor(recordId);
    final rows = await db.query(
      'photos',
      where: 'record_id IN (${_marks(keys)})',
      whereArgs: keys,
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(Photo.fromMap).toList();
  }

  static Future<List<Photo>> getPhotos(String recordId) async {
    final db = await database;
    final rows = await db.query(
      'photos',
      where: 'record_id = ?',
      whereArgs: [recordId],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(Photo.fromMap).toList();
  }

  static Future<void> insertPhoto(Photo p) async {
    final db = await database;
    await db.insert('photos', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> deletePhoto(String id) async {
    final db = await database;
    await db.delete('photos', where: 'id = ?', whereArgs: [id]);
  }

  // ── GPS Tracks ──────────────────────────────────────────────────────────────

  static Future<List<GpsTrack>> getAllTracks() async {
    final db = await database;
    final rows =
        await db.query('gps_tracks', orderBy: 'started_at DESC');
    return rows.map(GpsTrack.fromMap).toList();
  }

  static Future<void> insertTrack(GpsTrack t) async {
    final db = await database;
    await db.insert('gps_tracks', t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateTrack(GpsTrack t) async {
    final db = await database;
    await db.update('gps_tracks', t.toMap(),
        where: 'id = ?', whereArgs: [t.id]);
  }

  static Future<void> deleteTrack(String id) async {
    final db = await database;
    await db.delete('gps_tracks', where: 'id = ?', whereArgs: [id]);
  }
}
