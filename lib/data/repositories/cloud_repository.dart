import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/btk_record.dart';
import 'data_repository.dart';

/// Stores BTK records in Firestore under users/{uid}/btk_records/{id}.
/// Firestore offline persistence is enabled globally in main.dart, so
/// reads/writes survive network gaps automatically.
class CloudRepository implements DataRepository {
  CloudRepository({required this.uid});

  final String uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('btk_records');

  // ── DataRepository ──────────────────────────────────────────────────────────

  @override
  Future<List<BtkRecord>> getAll() async {
    final snap = await _col.orderBy('date', descending: true).get();
    return snap.docs.map((d) => BtkRecord.fromJson(d.data())).toList();
  }

  @override
  Future<bool> upsert(BtkRecord record) async {
    record.updatedAt = DateTime.now();
    await _col.doc(record.id).set(record.toJson());
    return false;
  }

  @override
  Future<void> delete(String id) => _col.doc(id).delete();

  /// Real-time stream — Firestore notifies on any change (including
  /// changes made on another device / from the web).
  @override
  Stream<List<BtkRecord>> get stream =>
      _col.orderBy('date', descending: true).snapshots().map(
            (snap) =>
                snap.docs.map((d) => BtkRecord.fromJson(d.data())).toList(),
          );
}
