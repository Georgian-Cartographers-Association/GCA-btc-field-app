import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/app_messenger.dart';
import '../../../models/btk_record.dart';
import '../../../data/repositories/cloud_repository.dart';
import '../../../data/repositories/data_repository.dart';
import '../../../data/repositories/expedition_repository.dart';
import '../../../data/repositories/local_repository.dart';
import '../../../data/sync/record_versions.dart';
import '../../auth/domain/firebase_auth_provider.dart';
import '../../settings/domain/settings_provider.dart';

class BtkNotifier extends StateNotifier<List<BtkRecord>> {
  BtkNotifier(this._repo) : super([]) {
    _init();
  }

  final DataRepository _repo;
  StreamSubscription<List<BtkRecord>>? _cloudSub;

  void _init() {
    final s = _repo.stream;
    if (s != null) {
      _cloudSub = s.listen((records) {
        if (mounted) state = records;
      }, onError: _reportLoadError);
    } else {
      _repo.getAll().then((records) {
        if (mounted) state = records;
      }, onError: _reportLoadError);
    }
  }

  void _reportLoadError(Object _) {
    AppMessenger.showError((l10n) => l10n.recordsLoadFailed);
  }

  static String _newId() => const Uuid().v4().substring(0, 8).toUpperCase();

  @override
  void dispose() {
    _cloudSub?.cancel();
    super.dispose();
  }

  Future<BtkRecord> add({double? lat, double? lon, String trackId = ''}) async {
    final record = BtkRecord(
      id: _newId(),
      date: DateTime.now(),
      latitude: lat,
      longitude: lon,
      trackId: trackId,
    );
    await _insert(record);
    return record;
  }

  /// Shows [record] right away, and removes it again if it can't be stored.
  Future<void> _insert(BtkRecord record) async {
    state = [...state, record];
    try {
      await _repo.upsert(record);
    } catch (_) {
      if (mounted) state = state.where((r) => r.id != record.id).toList();
      rethrow;
    }
  }

  /// Returns true if a sync conflict was detected, and the other version kept.
  /// Throws if the save fails. The edit stays on screen so it can be retried.
  Future<bool> update(BtkRecord record) async {
    state = [
      for (final r in state)
        if (r.id == record.id) record else r
    ];
    return _repo.upsert(record);
  }

  Future<void> remove(String id) async {
    final before = state;
    state = state.where((r) => r.id != id).toList();
    try {
      await _repo.delete(id);
    } catch (_) {
      if (mounted) state = before;
      rethrow;
    }
  }

  Future<BtkRecord> duplicate(BtkRecord original, String copySuffix) async {
    final json = original.toJson();
    json['id'] = _newId();
    json.remove('versions'); // the copy is a record of its own
    if ((json['name'] as String).isNotEmpty) {
      json['name'] = '${json['name']} $copySuffix';
    }
    final copy = BtkRecord.fromJson(json);
    await _insert(copy);
    return copy;
  }

  /// Makes a kept version the record again, replacing the current one by choice,
  /// so the current one must not count as a conflict with it.
  Future<void> restoreKept(BtkRecord kept) async {
    for (final current in state) {
      if (current.id == kept.id) {
        kept.versions = mergeVersions(kept.versions, current.versions);
      }
    }
    if (state.any((r) => r.id == kept.id)) {
      await update(kept);
    } else {
      await _insert(kept);
    }
  }

  /// Adds new records and replaces older copies. A copy that is the same age
  /// or newer than the imported one is kept, and counted in `skipped`.
  Future<({int added, int updated, int skipped})> importRecords(
      List<BtkRecord> records) async {
    final stateMap = {for (final r in state) r.id: r};
    int added = 0, updated = 0, skipped = 0;

    try {
      for (var r in records) {
        if (r.id.isEmpty) {
          r = BtkRecord.fromJson({...r.toJson(), 'id': _newId()});
        }
        final current = stateMap[r.id];
        if (current != null && !r.updatedAt.isAfter(current.updatedAt)) {
          skipped++;
          continue;
        }
        await _repo.upsert(r, keepUpdatedAt: true);
        stateMap[r.id] = r;
        if (current != null) {
          updated++;
        } else {
          added++;
        }
      }
    } finally {
      // Records written before a failure are stored, so they must show.
      if (mounted) {
        state = stateMap.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      }
    }

    return (added: added, updated: updated, skipped: skipped);
  }
}

/// Provider automatically recreates BtkNotifier when storage mode, auth state
/// or expedition ID changes — switching modes reloads data.
final btkProvider =
    StateNotifierProvider<BtkNotifier, List<BtkRecord>>((ref) {
  final settings = ref.watch(
    settingsProvider.select((s) => (
      mode: s.storageMode,
      expId: s.expeditionId,
    )),
  );
  final user = ref.watch(authProvider).valueOrNull;

  final DataRepository repo;
  switch (settings.mode) {
    case StorageMode.cloud:
      repo = user != null ? CloudRepository(uid: user.uid) : LocalRepository();
    case StorageMode.expedition:
      repo = (user != null && settings.expId != null)
          ? ExpeditionRepository(expeditionId: settings.expId!)
          : LocalRepository();
    case StorageMode.local:
      repo = LocalRepository();
  }

  return BtkNotifier(repo);
});
