import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/btk_record.dart';
import '../sync/conflict_guard.dart';
import 'data_repository.dart';
import 'firestore_write.dart';

/// Firestore-backed repository for a shared expedition.
/// Path: expeditions/{expeditionId}/btk_records/{recordId}
class ExpeditionRepository implements DataRepository {
  final String expeditionId;

  late final _guard = ConflictGuard(expeditionScope(expeditionId));

  ExpeditionRepository({required this.expeditionId});

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('expeditions')
          .doc(expeditionId)
          .collection('btk_records');

  @override
  Stream<List<BtkRecord>> get stream =>
      guardedRecords(_col.orderBy('date', descending: true), _guard);

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
}
