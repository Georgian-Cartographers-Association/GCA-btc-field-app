import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/domain/settings_provider.dart';
import '../../../data/services/sync_service.dart';

class AuthFormState {
  final bool isLogin;
  final bool busy;
  final String? error;
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
        error: error == _keep ? this.error : error as String?,
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
            error: 'წვდომა შეზღუდულია. '
                'ადმინისტრატორს მიმართეთ ამ ელ-ფოსტის დასამატებლად.',
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
            error: 'წვდომა შეზღუდულია. '
                'ადმინისტრატორს მიმართეთ ამ ელ-ფოსტის დასამატებლად.',
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
      state = state.copyWith(busy: false, error: _authError(e.code));
      return null;
    } catch (e) {
      state = state.copyWith(busy: false, error: 'შეცდომა: $e');
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

  /// Sends password reset email. Returns true on success.
  Future<bool> forgotPassword(String email) async {
    if (email.isEmpty) {
      state = state.copyWith(error: 'ჯერ შეიყვანეთ ელ-ფოსტა');
      return false;
    }
    state = state.copyWith(busy: true, error: null);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      state = state.copyWith(busy: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(busy: false, error: _authError(e.code));
      return false;
    }
  }

  Future<bool> _isEmailAllowed(String email) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('allowed_users')
          .doc(email)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  String _authError(String code) => switch (code) {
        'user-not-found' => 'მომხმარებელი ვერ მოიძებნა',
        'wrong-password' => 'პაროლი არასწორია',
        'email-already-in-use' => 'ეს ელ-ფოსტა უკვე გამოყენებულია',
        'weak-password' => 'პაროლი ძალიან სუსტია (მინ. 6 სიმბოლო)',
        'invalid-email' => 'ელ-ფოსტის ფორმატი არასწორია',
        'too-many-requests' => 'ძალიან ბევრი მცდელობა — ცოტა ხანი დაიცადეთ',
        'network-request-failed' => 'ქსელის შეცდომა — შეამოწმეთ ინტერნეტი',
        _ => 'შეცდომა ($code)',
      };
}

final authFormProvider =
    StateNotifierProvider.autoDispose<AuthFormNotifier, AuthFormState>(
        (ref) => AuthFormNotifier(ref));
