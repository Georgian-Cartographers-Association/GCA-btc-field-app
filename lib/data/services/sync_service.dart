import 'package:flutter/foundation.dart' show visibleForTesting;
import '../repositories/cloud_repository.dart';
import '../repositories/data_repository.dart';
import '../repositories/local_repository.dart';

class SyncService {
  /// Upload local records to Firestore. Safe to call multiple times.
  static Future<int> uploadLocalToCloud(String uid) =>
      copyNewer(from: LocalRepository(), to: CloudRepository(uid: uid));

  /// Download cloud records to local storage (reverse migration).
  static Future<int> downloadCloudToLocal(String uid) =>
      copyNewer(from: CloudRepository(uid: uid), to: LocalRepository());

  /// Copies records that are missing or older in [to], and returns how many.
  /// A newer copy in [to] is never overwritten.
  @visibleForTesting
  static Future<int> copyNewer({
    required DataRepository from,
    required DataRepository to,
  }) async {
    final existing = {for (final r in await to.getAll()) r.id: r};
    var copied = 0;
    for (final r in await from.getAll()) {
      final current = existing[r.id];
      if (current != null && !r.updatedAt.isAfter(current.updatedAt)) continue;
      await to.upsert(r, keepUpdatedAt: true);
      copied++;
    }
    return copied;
  }
}
