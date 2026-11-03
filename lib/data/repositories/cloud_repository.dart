import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/btk_record.dart';
import '../sync/conflict_guard.dart';
import 'data_repository.dart';
import 'firestore_write.dart';

/// Stores BTK records in Firestore under users/{uid}/btk_records/{id}.
/// Firestore offline persistence is enabled globally in main.dart, so
/// reads/writes survive network gaps automatically.
class CloudRepository implements DataRepository {
  CloudRepository({required this.uid});

  final String uid;

  late final _guard = ConflictGuard(userScope(uid));

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('btk_records');

  // ── DataRepository ──────────────────────────────────────────────────────────

  @override
  Future<List<BtkRecord>> getAll() async {
    final snap = await _col.orderBy('date', descending: true).get();
    return snap.docs.map((d) => BtkRecord.fromStored(d.id, d.data())).toList();
  }

  @override
  Future<bool> upsert(BtkRecord record, {bool keepUpdatedAt = false}) async {
    final docRef = _col.doc(record.id);
    final conflicted = await _guard.beforeWrite(record, await readCachedRecord(docRef),
        bulk: keepUpdatedAt);
    if (!keepUpdatedAt) record.updatedAt = DateTime.now();
    final sent = BtkRecord.fromStored(record.id, record.toJson());
    sendToFirestore(docRef.set(sent.toJson()), onRefused: () => _guard.keepRefused(sent));
    return conflicted;
  }

  @override
  Future<void> delete(String id) async {
    await _guard.beforeDelete(id);
    sendToFirestore(_col.doc(id).delete());
  }

  /// Real-time stream — Firestore notifies on any change (including
  /// changes made on another device / from the web).
  @override
  Stream<List<BtkRecord>> get stream =>
      guardedRecords(_col.orderBy('date', descending: true), _guard);
}
