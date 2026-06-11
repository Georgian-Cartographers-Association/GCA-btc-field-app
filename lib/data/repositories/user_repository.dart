import 'package:firebase_auth/firebase_auth.dart';

/// Lightweight snapshot of the authenticated user's identity.
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    required this.emailVerified,
    this.createdAt,
    this.lastSignInAt,
  });

  bool get isValid => uid.isNotEmpty && email.isNotEmpty;

  @override
  String toString() => 'UserProfile($email, verified=$emailVerified)';
}

/// Data-layer repository for the current user's profile.
///
/// Reads from FirebaseAuth and caches the result in memory for [_ttl].
/// Call [invalidate] on sign-out so the next call always hits Firebase.
class UserRepository {
  static const _ttl = Duration(minutes: 10);

  UserProfile? _cached;
  DateTime? _cachedAt;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Returns the cached profile if still fresh; otherwise fetches from
  /// FirebaseAuth and re-caches.  Returns null when not signed in.
  Future<UserProfile?> getProfile() async {
    final hit = _fromCache();
    if (hit != null) return hit;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Reload to get the latest emailVerified flag, etc.
    try {
      await user.reload();
    } catch (_) {
      // Network unavailable — proceed with stale Firebase token data.
    }

    final fresh = FirebaseAuth.instance.currentUser;
    if (fresh == null) return null;

    _cached = UserProfile(
      uid: fresh.uid,
      email: fresh.email ?? '',
      displayName: fresh.displayName,
      emailVerified: fresh.emailVerified,
      createdAt: fresh.metadata.creationTime,
      lastSignInAt: fresh.metadata.lastSignInTime,
    );
    _cachedAt = DateTime.now();
    return _cached;
  }

  /// Synchronous read of the cached profile (null if not cached or expired).
  UserProfile? get cachedProfile => _fromCache();

  /// Clears the in-memory cache — call on sign-out or explicit refresh.
  void invalidate() {
    _cached = null;
    _cachedAt = null;
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  UserProfile? _fromCache() {
    if (_cached == null || _cachedAt == null) return null;
    if (DateTime.now().difference(_cachedAt!) >= _ttl) return null;
    return _cached;
  }
}
