import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/btk_record.dart';
import 'data_repository.dart';
import 'firestore_write.dart';

/// Firestore-backed repository for a shared expedition.
/// Path: expeditions/{expeditionId}/btk_records/{recordId}
class ExpeditionRepository implements DataRepository {
  final String expeditionId;

  ExpeditionRepository({required this.expeditionId});

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('expeditions')
          .doc(expeditionId)
          .collection('btk_records');

  @override
  Stream<List<BtkRecord>> get stream =>
      _col.orderBy('date', descending: true).snapshots().map(
            (snap) => snap.docs
                .map((d) => BtkRecord.fromStored(d.id, d.data()))
                .toList(),
          );

  @override
  Future<List<BtkRecord>> getAll() async {
    final snap = await _col.orderBy('date', descending: true).get();
    return snap.docs.map((d) => BtkRecord.fromStored(d.id, d.data())).toList();
  }

  @override
  Future<bool> upsert(BtkRecord record, {bool keepUpdatedAt = false}) async {
    final docRef = _col.doc(record.id);
    final conflicted = await _newerInCache(docRef, record.updatedAt);
    // Always write — last-write-wins, but caller is informed of the conflict.
    if (!keepUpdatedAt) record.updatedAt = DateTime.now();
    sendToFirestore(docRef.set(record.toJson()));
    return conflicted;
  }

  /// Compares with the local cache, which the live stream keeps current. A
  /// transaction would give a stricter check but cannot run offline.
  Future<bool> _newerInCache(
      DocumentReference<Map<String, dynamic>> docRef, DateTime localTs) async {
    try {
      final snap = await docRef.get(const GetOptions(source: Source.cache));
      final raw = snap.data()?['updatedAt'];
      final serverTs = raw is String ? DateTime.tryParse(raw) : null;
      return serverTs != null && serverTs.isAfter(localTs);
    } on FirebaseException {
      return false; // not in the cache yet
    }
  }

  @override
  Future<void> delete(String id) async {
    sendToFirestore(_col.doc(id).delete());
  }
}
