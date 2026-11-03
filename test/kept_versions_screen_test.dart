import 'package:btk_field_app/data/repositories/data_repository.dart';
import 'package:btk_field_app/data/sync/conflict_store.dart';
import 'package:btk_field_app/features/records/domain/btk_provider.dart';
import 'package:btk_field_app/features/sync/domain/kept_versions_provider.dart';
import 'package:btk_field_app/features/sync/ui/kept_versions_screen.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements DataRepository {
  final Map<String, BtkRecord> stored;
  bool failWrites = false;

  _Repo(this.stored);

  @override
  Stream<List<BtkRecord>>? get stream => null;

  @override
  Future<List<BtkRecord>> getAll() async => stored.values.toList();

  @override
  Future<bool> upsert(BtkRecord record, {bool keepUpdatedAt = false}) async {
    if (failWrites) throw StateError('write failed');
    stored[record.id] = record;
    return false;
  }

  @override
  Future<void> delete(String id) async => stored.remove(id);
}

BtkRecord _record(String name, Map<String, int> versions) =>
    BtkRecord(id: 'A', date: DateTime(2026), name: name, versions: versions);

void main() {
  late _Repo repo;
  late WebConflictStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = WebConflictStore();
    ConflictStore.instance = store;
    repo = _Repo({'A': _record('current', {'b': 1})});
  });

  // The store's work isn't on the test's fake clock.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pumpAndSettle();
    }
  }

  // A tall window, so the whole comparison and its buttons fit.
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        syncScopeProvider.overrideWithValue('s'),
        btkProvider.overrideWith((_) => BtkNotifier(repo)),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // The records screen keeps the records loaded behind the banner.
        home: Scaffold(
          body: Consumer(builder: (context, ref, child) {
            ref.watch(btkProvider);
            return const KeptVersionsBanner();
          }),
        ),
      ),
    ));
    await settle(tester);
  }

  Future<void> review(WidgetTester tester) async {
    await tester.tap(find.byType(KeptVersionsBanner));
    await settle(tester);
    await tester.tap(find.text('kept'));
    await settle(tester);
  }

  testWidgets('no banner without kept versions', (tester) async {
    await open(tester);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('keeping both adds the version as a new record', (tester) async {
    await tester.runAsync(() => store.addKept('s', _record('kept', {'a': 1})));
    await open(tester);
    expect(find.text('Kept versions to review: 1'), findsOneWidget);
    await review(tester);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Kept version'), findsOneWidget);

    await tester.tap(find.text('Keep both'));
    await settle(tester);

    expect(repo.stored['A']!.name, 'current');
    final copy = repo.stored.values.firstWhere((r) => r.id != 'A');
    expect(copy.name, 'kept (copy)');
    expect(copy.versions, isEmpty);
    expect(await tester.runAsync(() => store.kept('s')), isEmpty);
  });

  testWidgets('replacing asks first, then takes in the current versions', (tester) async {
    await tester.runAsync(() => store.addKept('s', _record('kept', {'a': 1})));
    await open(tester);
    await review(tester);

    await tester.tap(find.text('Replace with this'));
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(repo.stored['A']!.name, 'current');

    await tester.tap(find.text('Replace with this'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(repo.stored['A']!.name, 'kept');
    expect(repo.stored['A']!.versions, {'a': 1, 'b': 1});
    expect(await tester.runAsync(() => store.kept('s')), isEmpty);
  });

  testWidgets('keeping the current one removes only the kept version', (tester) async {
    await tester.runAsync(() => store.addKept('s', _record('kept', {'a': 1})));
    await open(tester);
    await review(tester);

    await tester.tap(find.text('Keep current'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(repo.stored.keys, ['A']);
    expect(repo.stored['A']!.name, 'current');
    expect(await tester.runAsync(() => store.kept('s')), isEmpty);
  });

  testWidgets('a failed write leaves the kept version in place', (tester) async {
    await tester.runAsync(() => store.addKept('s', _record('kept', {'a': 1})));
    await open(tester);
    await review(tester);
    repo.failWrites = true;

    await tester.tap(find.text('Keep both'));
    await settle(tester);

    expect(await tester.runAsync(() async => (await store.kept('s')).length), 1);
  });

  testWidgets('a record deleted elsewhere can be restored', (tester) async {
    repo.stored.clear();
    await tester.runAsync(() => store.addKept('s', _record('kept', {'a': 1})));
    await open(tester);
    await review(tester);
    expect(find.text('Current'), findsNothing);

    await tester.tap(find.text('Restore'));
    await settle(tester);

    expect(repo.stored['A']!.name, 'kept');
    expect(await tester.runAsync(() => store.kept('s')), isEmpty);
  });
}
