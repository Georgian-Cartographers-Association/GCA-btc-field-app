import 'dart:convert';
import 'dart:io';
import 'package:btk_field_app/database/btk_database.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _recordsV1 = '''
  CREATE TABLE btk_records (
    id TEXT PRIMARY KEY,
    json TEXT NOT NULL,
    date TEXT NOT NULL,
    location TEXT DEFAULT '',
    latitude REAL,
    longitude REAL,
    updated_at TEXT NOT NULL
  )
''';
const _photosV1 = '''
  CREATE TABLE photos (
    id TEXT PRIMARY KEY,
    record_id TEXT NOT NULL,
    file_path TEXT NOT NULL,
    caption TEXT DEFAULT '',
    sort_order INTEGER DEFAULT 0,
    created_at TEXT NOT NULL
  )
''';
const _tracksV2 = '''
  CREATE TABLE gps_tracks (
    id TEXT PRIMARY KEY,
    started_at TEXT NOT NULL,
    ended_at TEXT,
    points_json TEXT NOT NULL DEFAULT '[]'
  )
''';

void main() {
  late Directory tmp;
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('btk_db_test');
    dbPath = p.join(tmp.path, 'test.db');
  });

  tearDown(() async {
    await (await BtkDatabase.database).close();
    await tmp.delete(recursive: true);
  });

  /// Creates a database as an older app version left it, with one record.
  Future<void> createOld(int version, List<String> statements) async {
    final db = await openDatabase(dbPath, version: version,
        onCreate: (db, _) async {
      for (final s in statements) {
        await db.execute(s);
      }
    });
    final old = BtkRecord(id: 'OLD00001', date: DateTime(2026), name: 'old');
    await db.insert('btk_records', {
      'id': old.id,
      'json': jsonEncode(old.toJson()),
      'date': old.date.toIso8601String(),
      'updated_at': old.date.toIso8601String(),
    });
    await db.close();
  }

  Future<void> expectOldKeptAndSaveWorks() async {
    expect((await BtkDatabase.getAllRecords()).single.name, 'old');
    await BtkDatabase.upsertRecord(
        BtkRecord(id: 'NEW00001', date: DateTime(2026, 2), name: 'new'));
    final ids = (await BtkDatabase.getAllRecords()).map((r) => r.id);
    expect(ids, unorderedEquals(['OLD00001', 'NEW00001']));
    expect(await BtkDatabase.getAllTracks(), isEmpty);
    expect(await (await BtkDatabase.database).getVersion(), 4);
  }

  test('new database saves and reads a record', () async {
    await BtkDatabase.openAt(dbPath);
    await BtkDatabase.upsertRecord(
        BtkRecord(id: 'NEW00001', date: DateTime(2026), name: 'new'));
    expect((await BtkDatabase.getAllRecords()).single.name, 'new');
  });

  test('version 1 database upgrades', () async {
    await createOld(1, [_recordsV1, _photosV1]);
    await BtkDatabase.openAt(dbPath);
    await expectOldKeptAndSaveWorks();
  });

  test('version 2 database upgrades', () async {
    await createOld(2, [_recordsV1, _photosV1, _tracksV2]);
    await BtkDatabase.openAt(dbPath);
    await expectOldKeptAndSaveWorks();
  });

  test('version 3 database with name column upgrades', () async {
    await createOld(3, [
      _recordsV1,
      _photosV1,
      _tracksV2,
      "ALTER TABLE btk_records ADD COLUMN name TEXT DEFAULT ''",
    ]);
    await BtkDatabase.openAt(dbPath);
    await expectOldKeptAndSaveWorks();
  });

  test('version 3 database missing name column is repaired', () async {
    await createOld(3, [_recordsV1, _photosV1, _tracksV2]);
    await BtkDatabase.openAt(dbPath);
    await expectOldKeptAndSaveWorks();
  });
}
