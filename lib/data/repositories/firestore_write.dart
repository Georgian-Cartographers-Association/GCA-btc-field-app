import 'dart:async';
import '../../core/app_messenger.dart';

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
