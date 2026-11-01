import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/localized_text.dart';

/// Lets non-UI code show a message on whatever screen is open.
class AppMessenger {
  static final key = GlobalKey<ScaffoldMessengerState>();

  static void showError(LocalizedText text) {
    final messenger = key.currentState;
    if (messenger == null) return;
    final l10n = AppLocalizations.of(messenger.context);
    if (l10n == null) return;
    messenger.showSnackBar(SnackBar(
      content: Text(text(l10n)),
      backgroundColor: Colors.red.shade700,
      duration: const Duration(seconds: 6),
    ));
  }
}
