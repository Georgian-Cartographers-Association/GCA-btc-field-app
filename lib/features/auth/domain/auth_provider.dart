import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/domain/settings_provider.dart';
import '../../../data/services/sync_service.dart';
import '../../../l10n/localized_text.dart';

class AuthFormState {
  final bool isLogin;
  final bool busy;
  final LocalizedText? error;
  final bool obscure;

  const AuthFormState({
    this.isLogin = true,
    this.busy = false,
    this.error,
    this.obscure = true,
  });

  AuthFormState copyWith({
    bool? isLogin,
    bool? busy,
    Object? error = _keep,
    bool? obscure,
  }) =>
      AuthFormState(
        isLogin: isLogin ?? this.isLogin,
        busy: busy ?? this.busy,
        error: error == _keep ? this.error : error as LocalizedText?,
        obscure: obscure ?? this.obscure,
      );
}

const _keep = Object();

class AuthFormNotifier extends StateNotifier<AuthFormState> {
  final Ref _ref;

  AuthFormNotifier(this._ref) : super(const AuthFormState());

  void toggleMode() =>
      state = state.copyWith(isLogin: !state.isLogin, error: null);

  void toggleObscure() => state = state.copyWith(obscure: !state.obscure);

  /// Signs in or registers. Returns uid on success, null on failure (error set in state).
  Future<String?> submit({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(busy: true, error: null);
    try {
      final UserCredential cred;
      if (state.isLogin) {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Allowlist check after login — sign out if not permitted.
        final allowed = await _isEmailAllowed(cred.user!.email ?? '');
        if (!allowed) {
          await FirebaseAuth.instance.signOut();
          state = state.copyWith(
            busy: false,
            error: (l10n) => l10n.accessDenied,
          );
          return null;
        }
      } else {
        // Allowlist check BEFORE creating the account so no orphan accounts
        // are left in Firebase Auth for non-permitted email addresses.
        final allowed = await _isEmailAllowed(email);
        if (!allowed) {
          state = state.copyWith(
            busy: false,
            error: (l10n) => l10n.accessDenied,
          );
          return null;
        }
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      state = state.copyWith(busy: false);
      return cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(busy: false, error: _authError(e));
      return null;
    } on FirebaseException catch (e) {
      final LocalizedText msg = e.code == 'permission-denied'
          ? (l10n) => l10n.authRulesError
          : (l10n) => l10n.authDbError(e.code);
      state = state.copyWith(busy: false, error: msg);
      return null;
    } catch (_) {
      state = state.copyWith(busy: false, error: (l10n) => l10n.authSystemError);
      return null;
    }
  }

  /// Uploads local records to cloud. Returns count on success, null on failure.
  Future<int?> uploadLocalData(String uid) async {
    state = state.copyWith(busy: true);
    try {
      final count = await SyncService.uploadLocalToCloud(uid);
      state = state.copyWith(busy: false);
      return count;
    } catch (_) {
      state = state.copyWith(busy: false);
      return null;
    }
  }

  Future<void> activateCloudMode() async {
    await _ref.read(settingsProvider.notifier).setStorageMode(StorageMode.cloud);
  }

  /// Sends password reset email.
  /// Returns the email used on success, null on failure (error set in state).
  Future<String?> forgotPassword(String email) async {
    if (email.trim().isEmpty) {
      state = state.copyWith(error: (l10n) => l10n.authEnterEmailFirst);
      return null;
    }
    state = state.copyWith(busy: true, error: null);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
          email: email.trim());
      state = state.copyWith(busy: false);
      return email.trim();
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(busy: false, error: _authError(e));
      return null;
    } catch (_) {
      state = state.copyWith(busy: false, error: (l10n) => l10n.authSystemError);
      return null;
    }
  }

  Future<bool> _isEmailAllowed(String email) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('allowed_users')
          .doc(email)
          .get();
      return doc.exists;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') rethrow;
      return false;
    }
  }

  LocalizedText _authError(FirebaseAuthException e) => switch (e.code) {
        // Login errors — old + new Firebase SDK codes
        'user-not-found' => (l10n) => l10n.authUserNotFound,
        'wrong-password' => (l10n) => l10n.authWrongPassword,
        'invalid-credential' => (l10n) => l10n.authInvalidCredential,
        'invalid-login-credentials' => (l10n) => l10n.authInvalidCredential,
        'INVALID_LOGIN_CREDENTIALS' => (l10n) => l10n.authInvalidCredential,
        // Registration errors
        'email-already-in-use' => (l10n) => l10n.authEmailInUse,
        'weak-password' => (l10n) => l10n.authWeakPassword,
        'invalid-email' => (l10n) => l10n.authInvalidEmail,
        'operation-not-allowed' => (l10n) => l10n.authMethodDisabled,
        // General
        'user-disabled' => (l10n) => l10n.authUserDisabled,
        'too-many-requests' => (l10n) => l10n.authTooManyRequests,
        'network-request-failed' => (l10n) => l10n.authNetworkError,
        _ => (l10n) =>
            '${l10n.authErrorCode(e.code)}${e.message != null ? '\n${e.message}' : ''}',
      };
}

final authFormProvider =
    StateNotifierProvider.autoDispose<AuthFormNotifier, AuthFormState>(
        (ref) => AuthFormNotifier(ref));
