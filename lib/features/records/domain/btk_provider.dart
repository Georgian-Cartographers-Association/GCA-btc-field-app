import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/btk_record.dart';
import '../../../data/repositories/cloud_repository.dart';
import '../../../data/repositories/data_repository.dart';
import '../../../data/repositories/expedition_repository.dart';
import '../../../data/repositories/local_repository.dart';
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
      });
    } else {
      _repo.getAll().then((records) {
        if (mounted) state = records;
      });
    }
  }

  @override
  void dispose() {
    _cloudSub?.cancel();
    super.dispose();
  }

  Future<BtkRecord> add({double? lat, double? lon}) async {
    final record = BtkRecord(
      id: const Uuid().v4().substring(0, 8).toUpperCase(),
      date: DateTime.now(),
      latitude: lat,
      longitude: lon,
    );
    state = [...state, record];
    await _repo.upsert(record);
    return record;
  }

  /// Returns true if a sync conflict was detected (expedition mode only).
  Future<bool> update(BtkRecord record) async {
    state = [
      for (final r in state)
        if (r.id == record.id) record else r
    ];
    return _repo.upsert(record);
  }

  Future<void> remove(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _repo.delete(id);
  }

  Future<BtkRecord> duplicate(BtkRecord original) async {
    final json = original.toJson();
    json['id'] = const Uuid().v4().substring(0, 8).toUpperCase();
    if ((json['name'] as String).isNotEmpty) {
      json['name'] = '${json['name']} (ასლი)';
    }
    final copy = BtkRecord.fromJson(json);
    state = [...state, copy];
    await _repo.upsert(copy);
    return copy;
  }

  Future<({int added, int updated})> importRecords(
      List<BtkRecord> records) async {
    final existingIds = {for (final r in state) r.id};
    int added = 0, updated = 0;

    for (final r in records) {
      if (existingIds.contains(r.id)) {
        updated++;
      } else {
        added++;
      }
      await _repo.upsert(r);
    }

    final stateMap = {for (final r in state) r.id: r};
    for (final r in records) {
      stateMap[r.id] = r;
    }
    if (mounted) {
      state = stateMap.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    return (added: added, updated: updated);
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
