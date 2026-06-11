import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/user_repository.dart';

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

// ── Data layer — UserRepository ─────────────────────────────────────────────

/// Single instance of [UserRepository] scoped to the app lifetime.
/// Invalidated automatically when auth state changes (sign-out).
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final repo = UserRepository();
  // Invalidate cache whenever auth state changes (e.g. sign-out).
  ref.listen(authProvider, (_, next) {
    if (next.valueOrNull == null) repo.invalidate();
  });
  return repo;
});

/// Domain layer — fetches [UserProfile] through the repository.
/// Checks cache first; falls back to Firebase only when stale or missing.
/// Presentation layer: watch this provider to get user info directly.
final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getProfile();
});
