import '../constants.dart';

extension DateTimeX on DateTime {
  /// Formats as Georgian date string: "15 იანვ 2024  09:30"
  String toGeorgianDateString() {
    final month = AppConstants.georgianMonths[this.month - 1];
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$day $month $year  $h:$min';
  }
}
