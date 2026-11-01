import '../../l10n/generated/app_localizations.dart';

extension DateTimeX on DateTime {
  /// Formats as a localized date string: "15 იანვ 2024  09:30", "15 Jan 2024  09:30"
  String toLocalizedDateString(AppLocalizations l10n) {
    final month = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr,
      l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug,
      l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
    ][this.month - 1];
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$day $month $year  $h:$min';
  }
}
