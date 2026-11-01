import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../settings/domain/settings_provider.dart';
import '../../../l10n/localized_text.dart';

class ExpeditionFormState {
  final bool busy;
  final String? createdCode;
  final LocalizedText? joinError;

  const ExpeditionFormState({
    this.busy = false,
    this.createdCode,
    this.joinError,
  });

  ExpeditionFormState copyWith({
    bool? busy,
    Object? createdCode = _keep,
    Object? joinError = _keep,
  }) =>
      ExpeditionFormState(
        busy: busy ?? this.busy,
        createdCode:
            createdCode == _keep ? this.createdCode : createdCode as String?,
        joinError: joinError == _keep ? this.joinError : joinError as LocalizedText?,
      );
}

const _keep = Object();

class ExpeditionFormNotifier extends StateNotifier<ExpeditionFormState> {
  final Ref _ref;

  ExpeditionFormNotifier(this._ref) : super(const ExpeditionFormState());

  CollectionReference<Map<String, dynamic>> get _expeditions =>
      FirebaseFirestore.instance.collection('expeditions');

  static String _generateCode() {
    final rng = Random.secure();
    return List.generate(
      AppConstants.expeditionCodeLength,
      (_) => AppConstants.expeditionCodeChars[
          rng.nextInt(AppConstants.expeditionCodeChars.length)],
    ).join();
  }

  Future<void> create() async {
    state = state.copyWith(busy: true, createdCode: null);
    try {
      final code = _generateCode();
      await _expeditions.doc(code).set({
        'created_at': FieldValue.serverTimestamp(),
      });
      state = state.copyWith(busy: false, createdCode: code);
    } catch (_) {
      state = state.copyWith(busy: false);
      rethrow;
    }
  }

  /// Joins the already-created code and activates expedition mode.
  /// Returns the code on success.
  Future<String?> confirmCreate() async {
    final code = state.createdCode;
    if (code == null) return null;
    await _ref.read(settingsProvider.notifier).joinExpedition(code);
    return code;
  }

  /// Validates and joins an existing expedition by [code].
  /// Returns the code on success, null on failure (joinError set in state).
  Future<String?> join(String code) async {
    if (code.length != AppConstants.expeditionCodeLength) {
      state = state.copyWith(
          joinError: (l10n) =>
              l10n.invalidCode(AppConstants.expeditionCodeLength));
      return null;
    }
    state = state.copyWith(busy: true, joinError: null);
    try {
      final doc = await _expeditions.doc(code).get();
      if (!doc.exists) {
        state = state.copyWith(
            busy: false, joinError: (l10n) => l10n.expeditionNotFound);
        return null;
      }
      await _ref.read(settingsProvider.notifier).joinExpedition(code);
      state = state.copyWith(busy: false);
      return code;
    } catch (e) {
      state = state.copyWith(busy: false, joinError: (l10n) => l10n.errorWithDetail('$e'));
      return null;
    }
  }

  void clearJoinError() => state = state.copyWith(joinError: null);
}

final expeditionFormProvider = StateNotifierProvider.autoDispose<
    ExpeditionFormNotifier, ExpeditionFormState>(
  (ref) => ExpeditionFormNotifier(ref),
);
