import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/sync/conflict_guard.dart';
import '../../../data/sync/conflict_store.dart';
import '../../../data/sync/sync_status.dart';
import '../../auth/domain/firebase_auth_provider.dart';
import '../../settings/domain/settings_provider.dart';

/// The shared space the records on screen belong to. Local mode has none.
final syncScopeProvider = Provider<String?>((ref) {
  final settings = ref.watch(
    settingsProvider.select((s) => (mode: s.storageMode, expId: s.expeditionId)),
  );
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return null;
  return switch (settings.mode) {
    StorageMode.cloud => userScope(user.uid),
    StorageMode.expedition =>
      settings.expId == null ? null : expeditionScope(settings.expId!),
    StorageMode.local => null,
  };
});

final keptVersionsProvider = StreamProvider.autoDispose<List<KeptVersion>>((ref) async* {
  final scope = ref.watch(syncScopeProvider);
  if (scope == null) {
    yield const [];
    return;
  }
  final store = ConflictStore.instance;
  yield await store.kept(scope);
  await for (final _ in store.changes) {
    yield await store.kept(scope);
  }
});

final syncStatusProvider = StreamProvider.autoDispose<SyncStatus?>((ref) async* {
  final scope = ref.watch(syncScopeProvider);
  if (scope == null) {
    yield null;
    return;
  }
  final feed = SyncStatusFeed.instance;
  yield feed.latest(scope);
  await for (final changed in feed.changes) {
    if (changed == scope) yield feed.latest(scope);
  }
});
