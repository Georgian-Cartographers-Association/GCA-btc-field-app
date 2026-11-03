import 'package:btk_field_app/data/repositories/data_repository.dart';
import 'package:btk_field_app/data/sync/sync_status.dart';
import 'package:btk_field_app/features/records/domain/btk_provider.dart';
import 'package:btk_field_app/features/sync/domain/kept_versions_provider.dart';
import 'package:btk_field_app/features/sync/ui/sync_status_button.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('feed', () {
    test('notes the time when everything is confirmed, and keeps it while offline', () async {
      final feed = SyncStatusFeed();
      await feed.report('s',
          pendingIds: {'A'}, hasPending: true, fromCache: false, now: () => DateTime(2026, 1, 1));
      expect(feed.latest('s')!.lastSynced, isNull);
      expect(feed.latest('s')!.isSynced, isFalse);

      await feed.report('s',
          pendingIds: {}, hasPending: false, fromCache: false, now: () => DateTime(2026, 1, 2));
      expect(feed.latest('s')!.lastSynced, DateTime(2026, 1, 2));
      expect(feed.latest('s')!.isSynced, isTrue);

      // Still synced: the time it became so stands for now.
      await feed.report('s',
          pendingIds: {}, hasPending: false, fromCache: false, now: () => DateTime(2026, 1, 3));
      expect(feed.latest('s')!.lastSynced, DateTime(2026, 1, 2));

      await feed.report('s',
          pendingIds: {}, hasPending: false, fromCache: true, now: () => DateTime(2026, 1, 4));
      expect(feed.latest('s')!.offline, isTrue);
      expect(feed.latest('s')!.lastSynced, DateTime(2026, 1, 2));
    });

    test('scopes stay apart, and the time survives a restart', () async {
      await SyncStatusFeed().report('s',
          pendingIds: {}, hasPending: false, fromCache: false, now: () => DateTime(2026, 1, 2));
      final restarted = SyncStatusFeed();
      expect(restarted.latest('s'), isNull);
      await restarted.report('s', pendingIds: {'A'}, hasPending: true, fromCache: true);
      expect(restarted.latest('s')!.lastSynced, DateTime(2026, 1, 2));
      expect(restarted.latest('other'), isNull);
    });
  });

  Future<void> pump(WidgetTester tester, String? scope, SyncStatus? status) async {
    await tester.pumpWidget(ProviderScope(
      key: ValueKey(scope),
      overrides: [
        syncScopeProvider.overrideWithValue(scope),
        syncStatusProvider.overrideWith((_) => Stream.value(status)),
        keptVersionsProvider.overrideWith((_) => Stream.value(const [])),
        btkProvider.overrideWith((_) => _Records([
              BtkRecord(id: 'A', date: DateTime(2026), name: 'waiting one'),
              BtkRecord(id: 'B', date: DateTime(2026), name: 'sent one'),
            ])),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SyncStatusButton()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('local mode shows nothing', (tester) async {
    await pump(tester, null, null);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('each state has its icon', (tester) async {
    await pump(tester, 'unknown', null);
    expect(find.byIcon(Icons.cloud_queue), findsOneWidget);
    await pump(tester, 's', const SyncStatus());
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    await pump(tester, 't', const SyncStatus(hasPending: true));
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    await pump(tester, 'u', const SyncStatus(offline: true, hasPending: true));
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });

  testWidgets('the sheet lists what is waiting', (tester) async {
    await pump(
      tester,
      's',
      SyncStatus(
        offline: true,
        hasPending: true,
        pendingIds: const {'A'},
        lastSynced: DateTime(2026, 11, 3, 9, 30),
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('Offline: changes are on this device'), findsOneWidget);
    expect(find.text('Last synced: 2026-11-03 09:30'), findsOneWidget);
    expect(find.text('Records waiting to be sent: 1'), findsOneWidget);
    expect(find.text('waiting one'), findsOneWidget);
    expect(find.text('sent one'), findsNothing);
  });
}

class _Records extends BtkNotifier {
  _Records(List<BtkRecord> records) : super(_NoRepo()) {
    state = records;
  }
}

class _NoRepo implements DataRepository {
  @override
  Stream<List<BtkRecord>>? get stream => const Stream.empty();
  @override
  Future<List<BtkRecord>> getAll() async => [];
  @override
  Future<bool> upsert(BtkRecord record, {bool keepUpdatedAt = false}) async => false;
  @override
  Future<void> delete(String id) async {}
}
