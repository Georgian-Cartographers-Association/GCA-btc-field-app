import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Permanent deletion of the signed-in user's account (Google Play
/// account-deletion requirement).
///
/// Deletes users/{uid}/btk_records/* and then the Firebase Auth account.
/// Local (on-device) records are not touched. Records already shared into
/// an expedition belong to that expedition and are kept.
class AccountService {
  static const _batchSize = 400;

  /// Throws [FirebaseAuthException] (e.g. `invalid-credential`) or
  /// [FirebaseException] on failure; nothing is deleted if re-auth fails.
  static Future<void> deleteAccount(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }

    // Firebase requires a recent sign-in before deleting an account.
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: password),
    );

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final records = userDoc.collection('btk_records');
    while (true) {
      final snap = await records.limit(_batchSize).get();
      if (snap.docs.isEmpty) break;
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    try {
      await userDoc.delete();
    } on FirebaseException catch (_) {
      // Parent doc usually doesn't exist or rules forbid it — records are gone.
    }

    await user.delete();
  }
}
