import 'dart:convert';
import 'dart:io';
import 'package:btk_field_app/data/repositories/data_repository.dart';
import 'package:btk_field_app/data/services/export_service.dart';
import 'package:btk_field_app/data/services/migration_service.dart';
import 'package:btk_field_app/data/services/sync_service.dart';
import 'package:btk_field_app/database/btk_database.dart';
import 'package:btk_field_app/features/records/domain/btk_provider.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:btk_field_app/models/photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeRepository implements DataRepository {
  FakeRepository([List<BtkRecord> records = const []])
      : stored = {for (final r in records) r.id: r};

  final Map<String, BtkRecord> stored;
  bool failWrites = false;

  @override
  Stream<List<BtkRecord>>? get stream => null;

  @override
  Future<List<BtkRecord>> getAll() async => stored.values.toList();

  @override
  Future<bool> upsert(BtkRecord record, {bool keepUpdatedAt = false}) async {
    if (failWrites) throw StateError('write failed');
    if (!keepUpdatedAt) record.updatedAt = DateTime.now();
    stored[record.id] = record;
    return false;
  }

  @override
  Future<void> delete(String id) async {
    if (failWrites) throw StateError('write failed');
    stored.remove(id);
  }
}

BtkRecord record(String id, DateTime updatedAt, {String name = ''}) =>
    BtkRecord(id: id, date: DateTime(2026), name: name, updatedAt: updatedAt);

Future<BtkNotifier> notifierWith(FakeRepository repo) async {
  final notifier = BtkNotifier(repo);
  await Future<void>.delayed(Duration.zero);
  return notifier;
}

void main() {
  final older = DateTime(2026, 1);
  final newer = DateTime(2026, 2);

  group('reading damaged data', () {
    test('wrong types do not throw', () {
      final r = BtkRecord.fromJson({
        'id': 7,
        'name': 12,
        'altitude': '1200.5',
        'latitude': 'not a number',
        'vegetation': [
          {'tier': 1},
          'bad row',
        ],
        'soilHorizons': 'bad list',
      });
      expect(r.id, '7');
      expect(r.name, '12');
      expect(r.altitude, 1200.5);
      expect(r.latitude, isNull);
      expect(r.vegetation.single.tier, '1');
      expect(r.soilHorizons, hasLength(1));
    });

    test('a valid record reads back unchanged', () {
      final r = record('A1', newer, name: 'x')
        ..latitude = 42.5
        ..vegetation = [VegetationRow(species: 'Fagus')];
      final copy = BtkRecord.fromJson(
          jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>);
      expect(copy.toJson(), r.toJson());
    });

    test('missing updatedAt falls back to the record date', () {
      final r = BtkRecord.fromJson({'id': 'A', 'date': '2020-05-01'});
      expect(r.updatedAt, DateTime(2020, 5));
    });

    test('fromStored fills in a missing id only', () {
      expect(BtkRecord.fromStored('DOC', {}).id, 'DOC');
      expect(BtkRecord.fromStored('DOC', {'id': 'OWN'}).id, 'OWN');
    });
  });

  group('importRecords', () {
    test('adds new, replaces older, keeps newer and timestamps', () async {
      final repo = FakeRepository([
        record('OLD', older, name: 'local old'),
        record('NEW', newer, name: 'local new'),
      ]);
      final notifier = await notifierWith(repo);

      final result = await notifier.importRecords([
        record('OLD', newer, name: 'imported'),
        record('NEW', older, name: 'imported'),
        record('ADD', older, name: 'imported'),
      ]);

      expect(result, (added: 1, updated: 1, skipped: 1));
      expect(repo.stored['OLD']!.name, 'imported');
      expect(repo.stored['OLD']!.updatedAt, newer);
      expect(repo.stored['NEW']!.name, 'local new');
      expect(repo.stored['ADD']!.updatedAt, older);
      expect(notifier.state, hasLength(3));
    });

    test('a record with no id gets a new one', () async {
      final repo = FakeRepository();
      final notifier = await notifierWith(repo);
      await notifier.importRecords([record('', older)]);
      expect(repo.stored.keys.single, isNotEmpty);
    });

    test('records written before a failure still show', () async {
      final repo = FakeRepository();
      final notifier = await notifierWith(repo);
      await notifier.importRecords([record('A', older)]);
      repo.failWrites = true;
      await expectLater(
          notifier.importRecords([record('B', older)]), throwsStateError);
      expect(notifier.state.map((r) => r.id), ['A']);
    });
  });

  group('failed writes', () {
    test('add removes the record again and throws', () async {
      final repo = FakeRepository()..failWrites = true;
      final notifier = await notifierWith(repo);
      await expectLater(notifier.add(), throwsStateError);
      expect(notifier.state, isEmpty);
    });

    test('remove restores the record and throws', () async {
      final repo = FakeRepository([record('A', older)]);
      final notifier = await notifierWith(repo);
      repo.failWrites = true;
      await expectLater(notifier.remove('A'), throwsStateError);
      expect(notifier.state.map((r) => r.id), ['A']);
    });

    test('update keeps the edit on screen and throws', () async {
      final repo = FakeRepository([record('A', older)]);
      final notifier = await notifierWith(repo);
      repo.failWrites = true;
      await expectLater(
          notifier.update(record('A', older, name: 'edited')), throwsStateError);
      expect(notifier.state.single.name, 'edited');
    });
  });

  test('copyNewer never overwrites a newer copy', () async {
    final from = FakeRepository([
      record('OLD', newer, name: 'from'),
      record('NEW', older, name: 'from'),
      record('ADD', older, name: 'from'),
    ]);
    final to = FakeRepository([
      record('OLD', older, name: 'to'),
      record('NEW', newer, name: 'to'),
    ]);

    expect(await SyncService.copyNewer(from: from, to: to), 2);
    expect(to.stored['OLD']!.name, 'from');
    expect(to.stored['NEW']!.name, 'to');
    expect(to.stored['ADD']!.updatedAt, older);
  });

  group('database', () {
    late Directory tmp;
    late AppLocalizations l10n;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('btk_safety_test');
      await BtkDatabase.openAt(p.join(tmp.path, 'test.db'));
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => tmp.path,
      );
    });

    tearDown(() async {
      await (await BtkDatabase.database).close();
      await tmp.delete(recursive: true);
    });

    Future<Photo> addPhoto(String id, String key) async {
      final file = File(p.join(tmp.path, '$id.jpg'));
      await file.writeAsBytes(utf8.encode('image $id'));
      final photo = Photo(
          id: id,
          recordId: key,
          filePath: file.path,
          createdAt: DateTime(2026));
      await BtkDatabase.insertPhoto(photo);
      return photo;
    }

    test('an unreadable row does not hide the others and is kept', () async {
      await BtkDatabase.upsertRecord(record('GOOD', older));
      final db = await BtkDatabase.database;
      await db.insert('btk_records', {
        'id': 'BAD',
        'json': '{broken',
        'date': '2026-01-01',
        'updated_at': '2026-01-01',
      });

      final (records, skipped) = await BtkDatabase.readAllRecords();
      expect(records.single.id, 'GOOD');
      expect(skipped, 1);
      expect(await db.query('btk_records', where: "id = 'BAD'"), hasLength(1));
    });

    test('deleting a record removes photo rows of all sections', () async {
      await BtkDatabase.upsertRecord(record('A', older));
      await BtkDatabase.upsertRecord(record('B', older));
      await addPhoto('p1', 'A');
      await addPhoto('p2', 'A_soil');
      await addPhoto('p3', 'A_vertStruct');
      await addPhoto('p4', 'B_soil');

      expect(await BtkDatabase.getRecordPhotos('A'), hasLength(3));
      await BtkDatabase.deleteRecord('A');

      expect(await BtkDatabase.getRecordPhotos('A'), isEmpty);
      expect(await BtkDatabase.getRecordPhotos('B'), hasLength(1));
    });

    test('.btkz keeps photos of all sections through a round trip', () async {
      final r = record('A', older, name: 'x');
      await BtkDatabase.upsertRecord(r);
      await addPhoto('p1', 'A');
      await addPhoto('p2', 'A_soil');
      await addPhoto('p3', 'A_vertStruct');

      final built = await ExportService.buildBtkz([r]);
      expect(built.photoCount, 3);

      await BtkDatabase.deleteRecord('A');
      final read = await ExportService.readBtkz(built.bytes, l10n);

      expect(read.records.single.name, 'x');
      expect(read.photoCount, 3);
      final restored = await BtkDatabase.getRecordPhotos('A');
      expect(restored.map((p) => p.recordId).toSet(),
          {'A', 'A_soil', 'A_vertStruct'});
      expect(await File(restored.first.filePath).exists(), isTrue);
    });

    test('migration retries after a failure, without overwriting', () async {
      final oldJson = record('A', older, name: 'from prefs').toJson();
      SharedPreferences.setMockInitialValues({
        'btk_records': jsonEncode([oldJson]),
      });

      await (await BtkDatabase.database).close();
      await MigrationService.migrateIfNeeded(); // database closed, so it fails
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sqlite_migrated_v1'), isNot(true));

      await BtkDatabase.openAt(p.join(tmp.path, 'test.db'));
      await BtkDatabase.upsertRecord(record('A', newer, name: 'edited'));
      await MigrationService.migrateIfNeeded();

      expect(prefs.getBool('sqlite_migrated_v1'), isTrue);
      expect((await BtkDatabase.getAllRecords()).single.name, 'edited');
    });
  });
}
