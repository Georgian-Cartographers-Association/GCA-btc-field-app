import 'dart:io';

import 'package:btk_field_app/data/sync/conflict_guard.dart';
import 'package:btk_field_app/data/sync/conflict_store.dart';
import 'package:btk_field_app/data/sync/record_versions.dart';
import 'package:btk_field_app/database/btk_database.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

BtkRecord _record(String name, {Map<String, int>? versions, DateTime? updatedAt}) => BtkRecord(
      id: 'A',
      date: DateTime(2026),
      name: name,
      versions: versions,
      updatedAt: updatedAt ?? DateTime(2026, 1, 1),
    );

BtkRecord _copy(BtkRecord r) => BtkRecord.fromJson(r.toJson());

/// One phone: its own store, and what it has last seen of the record.
class _Device {
  final String id;
  final ConflictStore store;
  late final guard = ConflictGuard('s', store: store, deviceId: () async => id);
  BtkRecord? seen;

  _Device(this.id, this.store);

  /// Edits its own copy and saves. The result is what reaches the server.
  Future<BtkRecord> edit(String name) async {
    final record = seen == null ? _record(name) : (_copy(seen!)..name = name);
    await guard.beforeWrite(record, seen);
    return seen = record;
  }

  Future<void> receive(BtkRecord server) async {
    await guard.afterSnapshot([_copy(server)], complete: true);
    seen = _copy(server);
  }

  Future<List<String>> keptNames() async =>
      [for (final k in await store.kept('s')) k.record.name];
}

void main() {
  group('compareVersions', () {
    test('tells the four cases apart', () {
      expect(compareVersions({'a': 1}, {'a': 1}), VersionOrder.same);
      expect(compareVersions({'a': 1}, {'a': 2}), VersionOrder.older);
      expect(compareVersions({'a': 2, 'b': 1}, {'a': 2}), VersionOrder.newer);
      expect(compareVersions({'a': 2}, {'b': 1}), VersionOrder.concurrent);
    });

    test('merging takes the higher count per device', () {
      expect(mergeVersions({'a': 3, 'b': 1}, {'b': 2, 'c': 1}), {'a': 3, 'b': 2, 'c': 1});
    });
  });

  group('inConflict', () {
    test('the same content never conflicts, whatever the versions', () {
      expect(inConflict(_record('x', versions: {'a': 1}), _record('x', versions: {'b': 1})), isFalse);
    });

    test('a copy made from the other does not conflict', () {
      expect(inConflict(_record('x', versions: {'a': 2}), _record('y', versions: {'a': 1})), isFalse);
    });

    test('copies from separate edits conflict', () {
      expect(inConflict(_record('x', versions: {'a': 1}), _record('y', versions: {'b': 1})), isTrue);
    });

    test('a save by an older app version conflicts with a versioned copy', () {
      expect(inConflict(_record('x', versions: {'a': 1}), _record('y')), isTrue);
    });

    test('two unversioned copies go by their clocks', () {
      final early = _record('x', updatedAt: DateTime(2026, 1, 1));
      final late = _record('y', updatedAt: DateTime(2026, 1, 2));
      expect(inConflict(early, late), isTrue);
      expect(inConflict(late, early), isFalse);
    });
  });

  group('wouldOverwrite', () {
    test('an edit of the latest copy does not', () {
      expect(wouldOverwrite(_record('x', versions: {'a': 1}), _record('y', versions: {'a': 1})), isFalse);
    });

    test('an edit started from an older copy does', () {
      expect(wouldOverwrite(_record('x', versions: {'a': 1}), _record('y', versions: {'a': 1, 'b': 1})), isTrue);
    });

    test('an old copy of the same content does not', () {
      expect(wouldOverwrite(_record('x', versions: {'a': 1}), _record('x', versions: {'a': 2})), isFalse);
    });
  });

  test('versions survive JSON, and an old record has none', () {
    final json = _record('x', versions: {'a': 3}).toJson();
    expect(BtkRecord.fromJson(json).versions, {'a': 3});
    final old = _record('x').toJson();
    expect(old.containsKey('versions'), isFalse);
    expect(BtkRecord.fromJson(old).versions, isEmpty);
    expect(BtkRecord.fromJson({...old, 'versions': 'junk'}).versions, isEmpty);
  });

  late Directory tmp;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('btk_conflict_test');
    await BtkDatabase.openAt(p.join(tmp.path, 'test.db'));
  });

  tearDown(() async {
    await (await BtkDatabase.database).close();
    await tmp.delete(recursive: true);
  });

  final stores = <String, ConflictStore Function()>{
    'SQLite': SqliteConflictStore.new,
    'Web': WebConflictStore.new,
  };

  stores.forEach((name, make) {
    group('$name store', () {
      test('keeps versions by scope, until removed', () async {
        final store = make();
        await store.addKept('s', _record('x'));
        await store.addKept('other', _record('y'));
        final kept = await store.kept('s');
        expect(kept.single.record.name, 'x');
        await store.removeKept(kept.single.id);
        expect(await store.kept('s'), isEmpty);
        expect((await store.kept('other')).single.record.name, 'y');
      });

      test('holds one last write per record', () async {
        final store = make();
        await store.setLastWrite('s', _record('first'));
        await store.setLastWrite('s', _record('second', versions: {'a': 2}));
        final writes = await store.lastWrites('s');
        expect(writes['A']!.name, 'second');
        expect(writes['A']!.versions, {'a': 2});
        await store.forgetLastWrite('s', 'A');
        expect(await store.lastWrites('s'), isEmpty);
      });

      test('says when the kept list changes', () async {
        final store = make();
        var changes = 0;
        final sub = store.changes.listen((_) => changes++);
        await store.addKept('s', _record('x'));
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();
        expect(changes, 1);
      });
    });
  });

  group('two devices', () {
    late _Device a;
    late _Device b;

    // Each device needs storage of its own, and there's one database here.
    setUp(() {
      a = _Device('a', SqliteConflictStore());
      b = _Device('b', WebConflictStore());
    });

    test('both edit offline: the version the server lost is kept', () async {
      final start = await a.edit('start');
      await b.receive(start);
      await a.receive(start);

      final fromA = await a.edit('from a');
      final fromB = await b.edit('from b');
      expect(fromA.versions, isNot(fromB.versions));

      // A's write reaches the server first, and B's replaces it.
      await a.receive(fromB);
      await b.receive(fromB);

      expect(await a.keptNames(), ['from a']);
      expect(await b.keptNames(), isEmpty);
    });

    test('taking turns online keeps nothing', () async {
      final one = await a.edit('one');
      await b.receive(one);
      final two = await b.edit('two');
      await a.receive(two);
      await b.receive(two);
      final three = await a.edit('three');
      await b.receive(three);
      await a.receive(three);

      expect(await a.keptNames(), isEmpty);
      expect(await b.keptNames(), isEmpty);
    });

    test('many saves on top of another device\'s still keep nothing', () async {
      final one = await a.edit('one');
      await b.receive(one);
      var latest = one;
      for (var i = 0; i < 50; i++) {
        latest = await b.edit('b $i');
      }
      await a.receive(latest);
      expect(await a.keptNames(), isEmpty);
    });

    test('an edit over a change already on this device keeps that change', () async {
      final one = await a.edit('one');
      await b.receive(one);
      final two = await b.edit('from b');
      // A's form was opened on 'one', and the stream has since brought 'two'.
      final stale = _copy(one)..name = 'from a';
      final conflict = await a.guard.beforeWrite(stale, _copy(two));

      expect(conflict, isTrue);
      expect(await a.keptNames(), ['from b']);
      expect(stale.versions, {'a': 2, 'b': 1});
      // Its version now includes B's, so B needn't keep anything too.
      await b.receive(stale);
      expect(await b.keptNames(), isEmpty);

      // Autosave repeats: the conflict is reported once.
      expect(await a.guard.beforeWrite(stale, _copy(stale)), isFalse);
      expect(await a.keptNames(), ['from b']);
    });

    test('an own write coming back changes nothing', () async {
      final one = await a.edit('one');
      await a.receive(one);
      expect(await a.keptNames(), isEmpty);
      expect((await a.store.lastWrites('s')).keys, ['A']);
    });

    test('a record deleted elsewhere is kept, once the server says so', () async {
      await a.edit('mine');
      await a.guard.afterSnapshot([], complete: false);
      expect(await a.keptNames(), isEmpty);
      await a.guard.afterSnapshot([], complete: true);
      expect(await a.keptNames(), ['mine']);
    });

    test('deleting it here keeps nothing', () async {
      await a.edit('mine');
      await a.guard.beforeDelete('A');
      await a.guard.afterSnapshot([], complete: true);
      expect(await a.keptNames(), isEmpty);
    });

    test('a refused save is kept, but not one already followed by another', () async {
      final first = _copy(await a.edit('first'));
      final second = _copy(await a.edit('second'));
      await a.guard.keepRefused(first);
      expect(await a.keptNames(), isEmpty);
      await a.guard.keepRefused(second);
      expect(await a.keptNames(), ['second']);
      expect(await a.store.lastWrites('s'), isEmpty);
    });

    test('a bulk copy sets versions without a conflict', () async {
      final record = _record('imported');
      final conflict = await a.guard
          .beforeWrite(record, _record('other', versions: {'b': 1}), bulk: true);
      expect(conflict, isFalse);
      expect(record.versions, {'a': 1, 'b': 1});
      expect(await a.keptNames(), isEmpty);
    });
  });
}
