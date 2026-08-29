import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/btk_record.dart';
import '../models/gps_track.dart';
import '../models/photo.dart';

/// SQLite wrapper — used on Android/native only.
/// Web continues to use SharedPreferences via BtkNotifier.
class BtkDatabase {
  static Database? _db;

  static Future<Database> get database async {
    assert(!kIsWeb, 'BtkDatabase is not available on web');
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = join(await getDatabasesPath(), 'btk_field_app.db');
    return openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, _) async {
        await _createV1(db);
        await _createV2(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createV2(db);
        if (oldVersion < 3) await _createV3(db);
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

  // ── BtkRecord ───────────────────────────────────────────────────────────────

  static Future<List<BtkRecord>> getAllRecords() async {
    final db = await database;
    final rows = await db.query('btk_records', orderBy: 'date DESC');
    return rows
        .map((r) => BtkRecord.fromJson(jsonDecode(r['json'] as String)))
        .toList();
  }

  static Future<void> upsertRecord(BtkRecord r) async {
    final db = await database;
    await db.insert(
      'btk_records',
      {
        'id': r.id,
        'json': jsonEncode(r.toJson()),
        'date': r.date.toIso8601String(),
        'name': r.name,
        'location': r.location,
        'latitude': r.latitude,
        'longitude': r.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteRecord(String id) async {
    final db = await database;
    await db.delete('btk_records', where: 'id = ?', whereArgs: [id]);
  }

  // ── Photos ──────────────────────────────────────────────────────────────────

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
