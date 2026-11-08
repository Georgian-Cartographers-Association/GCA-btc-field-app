import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_messenger.dart';
import '../../models/btk_record.dart';
import '../sync/conflict_guard.dart';
import '../sync/sync_status.dart';

/// Hands a write to Firestore without waiting for the server.
///
/// Firestore stores the write in its local cache at once and sends it when
/// online, but its Future only completes after the server confirms. Awaiting
/// it would block the UI for as long as the device is offline.
///
/// Being refused undoes the write in the cache as well, so [onRefused] is the
/// last chance to hold on to what it carried.
void sendToFirestore(Future<void> write, {Future<void> Function()? onRefused}) {
  unawaited(write.catchError((Object _) {
    AppMessenger.showError((l10n) => l10n.cloudSaveFailed);
    return onRefused?.call();
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

/// A live stream that also tells [guard] what arrived, and reports sync status.
/// Status uses its own listener: it needs every change in what's confirmed, which
/// shouldn't reload the records on screen each time. A failing check must not
/// stop the records from showing.
Stream<List<BtkRecord>> guardedRecords(
    Query<Map<String, dynamic>> query, ConflictGuard guard) {
  late final StreamController<List<BtkRecord>> controller;
  StreamSubscription<void>? records;
  StreamSubscription<void>? status;

  controller = StreamController<List<BtkRecord>>(
    onListen: () {
      records = query.snapshots().asyncMap((snap) async {
        final list =
            snap.docs.map((d) => BtkRecord.fromStored(d.id, d.data())).toList();
        try {
          await guard.afterSnapshot(list, complete: !snap.metadata.isFromCache);
        } catch (_) {
          AppMessenger.showError((l10n) => l10n.syncCheckFailed);
        }
        return list;
      }).listen(controller.add, onError: controller.addError);
      status = query.snapshots(includeMetadataChanges: true).listen((snap) {
        unawaited(SyncStatusFeed.instance.report(
          guard.scope,
          pendingIds: {
            for (final d in snap.docs)
              if (d.metadata.hasPendingWrites) d.id,
          },
          hasPending: snap.metadata.hasPendingWrites,
          fromCache: snap.metadata.isFromCache,
        ));
      }, onError: (Object _) {});
    },
    onCancel: () async {
      await records?.cancel();
      await status?.cancel();
    },
  );
  return controller.stream;
}
