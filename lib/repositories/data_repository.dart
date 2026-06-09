import '../models/btk_record.dart';

/// Abstract interface shared by LocalRepository and CloudRepository.
/// BtkNotifier only talks to this — never to SQLite or Firestore directly.
abstract class DataRepository {
  Future<List<BtkRecord>> getAll();
  /// Returns true if a sync conflict was detected (expedition mode only).
  Future<bool> upsert(BtkRecord record);
  Future<void> delete(String id);

  /// Optional: stream of all records (used by cloud repo for real-time sync).
  /// Local repo returns null — polling/one-shot load is used instead.
  Stream<List<BtkRecord>>? get stream => null;
}
