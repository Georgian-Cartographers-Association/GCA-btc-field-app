import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_messenger.dart';
import '../../models/btk_record.dart';
import '../sync/conflict_guard.dart';

/// Hands a write to Firestore without waiting for the server.
///
/// Firestore stores the write in its local cache at once and sends it when
/// online, but its Future only completes after the server confirms. Awaiting
/// it would block the UI for as long as the device is offline.
void sendToFirestore(Future<void> write) {
  unawaited(write.catchError((Object _) {
    AppMessenger.showError((l10n) => l10n.cloudSaveFailed);
  }));
}

/// The record as this device last saw it, which the live stream keeps current.
/// A transaction would give a stricter answer but cannot run offline.
Future<BtkRecord?> readCachedRecord(
    DocumentReference<Map<String, dynamic>> docRef) async {
  try {
    final snap = await docRef.get(const GetOptions(source: Source.cache));
    final data = snap.data();
    return data == null ? null : BtkRecord.fromStored(docRef.id, data);
  } on FirebaseException {
    return null; // not in the cache yet
  }
}

/// A live stream that also tells [guard] what arrived. A failing check must not
/// stop the records from showing.
Stream<List<BtkRecord>> guardedRecords(
    Query<Map<String, dynamic>> query, ConflictGuard guard) {
  return query.snapshots().asyncMap((snap) async {
    final records =
        snap.docs.map((d) => BtkRecord.fromStored(d.id, d.data())).toList();
    try {
      await guard.afterSnapshot(records, complete: !snap.metadata.isFromCache);
    } catch (_) {
      AppMessenger.showError((l10n) => l10n.syncCheckFailed);
    }
    return records;
  });
}
