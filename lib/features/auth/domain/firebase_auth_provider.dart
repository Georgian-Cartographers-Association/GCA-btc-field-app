import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the current Firebase [User] (null = signed out).
final authProvider = StreamProvider<User?>((ref) {
  try {
    return FirebaseAuth.instance.authStateChanges();
  } catch (_) {
    return const Stream.empty();
  }
});

/// Convenience accessor — synchronous read of the current user.
User? currentUser() {
  try {
    return FirebaseAuth.instance.currentUser;
  } catch (_) {
    return null;
  }
}
