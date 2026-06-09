import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/btk_record.dart';
import 'data_repository.dart';

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
                .map((d) => BtkRecord.fromJson(d.data()))
                .toList(),
          );

  @override
  Future<List<BtkRecord>> getAll() async {
    final snap = await _col.orderBy('date', descending: true).get();
    return snap.docs.map((d) => BtkRecord.fromJson(d.data())).toList();
  }

  @override
  Future<bool> upsert(BtkRecord record) async {
    bool conflicted = false;
    // Capture the local updatedAt before the transaction (it may retry).
    final localUpdatedAt = record.updatedAt;
    final docRef = _col.doc(record.id);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (snap.exists) {
        final raw = snap.data()!['updatedAt'];
        final serverTs =
            raw != null ? DateTime.tryParse(raw as String) : null;
        // If server version is newer than what we last read, it's a conflict.
        if (serverTs != null && serverTs.isAfter(localUpdatedAt)) {
          conflicted = true;
        }
      }
      // Always write — last-write-wins, but caller is informed of the conflict.
      record.updatedAt = DateTime.now();
      tx.set(docRef, record.toJson());
    });

    return conflicted;
  }

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}
