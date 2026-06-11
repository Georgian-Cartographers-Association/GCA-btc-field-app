import '../repositories/cloud_repository.dart';
import '../repositories/local_repository.dart';

class SyncService {
  /// Upload all local records to Firestore (one-time migration).
  /// Safe to call multiple times — uses upsert so duplicates are overwritten.
  static Future<int> uploadLocalToCloud(String uid) async {
    final local = LocalRepository();
    final cloud = CloudRepository(uid: uid);

    final records = await local.getAll();
    for (final r in records) {
      await cloud.upsert(r);
    }
    return records.length;
  }

  /// Download all cloud records to local storage (reverse migration).
  static Future<int> downloadCloudToLocal(String uid) async {
    final local = LocalRepository();
    final cloud = CloudRepository(uid: uid);

    final records = await cloud.getAll();
    for (final r in records) {
      await local.upsert(r);
    }
    return records.length;
  }
}
