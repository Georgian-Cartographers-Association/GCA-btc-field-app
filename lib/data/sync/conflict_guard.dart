import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/btk_record.dart';
import 'conflict_store.dart';
import 'record_versions.dart';

String userScope(String uid) => 'users/$uid';
String expeditionScope(String id) => 'expeditions/$id';

const _deviceKey = 'sync_device_id';

Future<String> syncDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString(_deviceKey);
  if (id == null) {
    id = const Uuid().v4().substring(0, 8);
    await prefs.setString(_deviceKey, id);
  }
  return id;
}

/// Keeps shared writes from losing data. Firestore lets the last write win, even
/// one sent long after it was made offline, and can't be asked to check first
/// without a connection. So whichever device sees that a version was replaced
/// keeps a copy of it here.
class ConflictGuard {
  final String scope;
  final ConflictStore store;
  final Future<String> Function() deviceId;

  ConflictGuard(this.scope, {ConflictStore? store, this.deviceId = syncDeviceId})
      : store = store ?? ConflictStore.instance;

  /// Call before writing [record] over [current], the copy on this device.
  /// Returns true if [current] held something [record] didn't, which is now kept.
  /// A bulk copy has already chosen by age, so it only needs its versions set.
  Future<bool> beforeWrite(BtkRecord record, BtkRecord? current, {bool bulk = false}) async {
    final conflict = !bulk && current != null && wouldOverwrite(record, current);
    if (conflict) await store.addKept(scope, current);

    final device = await deviceId();
    final versions = mergeVersions(record.versions, current?.versions ?? const {});
    versions[device] = (versions[device] ?? 0) + 1;
    record.versions = versions;
    await store.setLastWrite(scope, record);
    return conflict;
  }

  /// Call with each list from the live stream. [complete] says it came from the
  /// server, so a record missing from it really is gone and not just uncached.
  Future<void> afterSnapshot(List<BtkRecord> records, {required bool complete}) async {
    final writes = await store.lastWrites(scope);
    if (writes.isEmpty) return;
    final incoming = {for (final r in records) r.id: r};
    for (final MapEntry(key: id, value: mine) in writes.entries) {
      final theirs = incoming[id];
      if (theirs == null) {
        if (complete) {
          await store.addKept(scope, mine);
          await store.forgetLastWrite(scope, id);
        }
      } else if (inConflict(mine, theirs)) {
        await store.addKept(scope, mine);
        await store.forgetLastWrite(scope, id);
      } else if (compareVersions(mine.versions, theirs.versions) == VersionOrder.older) {
        // Someone built on this device's save, so it's part of the record now.
        await store.forgetLastWrite(scope, id);
      }
    }
  }

  /// The server refused [sent], and the record has gone back to what it was. Only
  /// the latest save needs keeping, since autosave's earlier ones led up to it.
  Future<void> keepRefused(BtkRecord sent) async {
    final last = (await store.lastWrites(scope))[sent.id];
    if (last == null || compareVersions(last.versions, sent.versions) != VersionOrder.same) {
      return;
    }
    await store.addKept(scope, sent);
    await store.forgetLastWrite(scope, sent.id);
  }

  /// This device deleted the record, so its absence is expected.
  Future<void> beforeDelete(String id) => store.forgetLastWrite(scope, id);
}
