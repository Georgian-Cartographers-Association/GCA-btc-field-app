import '../../l10n/generated/app_localizations.dart';

extension DurationX on Duration {
  /// Formats duration as a localized string: "2 სთ 15 წთ", "5 min 30 s", "45 s"
  String toLocalizedString(AppLocalizations l10n) {
    final h = inHours;
    final m = inMinutes.remainder(60);
    final s = inSeconds.remainder(60);
    if (h > 0) return '$h ${l10n.unitHour} $m ${l10n.unitMin}';
    if (m > 0) return '$m ${l10n.unitMin} $s ${l10n.unitSec}';
    return '$s ${l10n.unitSec}';
  }
}
