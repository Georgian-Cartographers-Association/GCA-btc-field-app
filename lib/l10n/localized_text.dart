import 'generated/app_localizations.dart';

/// Text kept in state or models that have no [BuildContext]. The UI resolves it
/// with its own [AppLocalizations], so it follows the current language.
typedef LocalizedText = String Function(AppLocalizations l10n);
