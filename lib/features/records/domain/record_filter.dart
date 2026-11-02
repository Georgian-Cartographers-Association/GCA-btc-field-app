import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/btk_record.dart';
import '../../../models/record_quality.dart';

/// What the map and the records list show. Filtering only hides records from
/// view: nothing is deleted, and both screens say when a filter is on.
class RecordFilter {
  /// Groups to show, where '' means records with no group. Empty shows all.
  final Set<String> groups;
  final bool unfinishedOnly;
  final DateTimeRange? dates;

  const RecordFilter({this.groups = const {}, this.unfinishedOnly = false, this.dates});

  bool get isActive => groups.isNotEmpty || unfinishedOnly || dates != null;

  bool matches(BtkRecord r) {
    if (groups.isNotEmpty && !groups.contains(r.group.trim())) return false;
    if (unfinishedOnly && !r.isUnfinished) return false;
    final range = dates;
    if (range != null) {
      // The end date counts as a whole day.
      final end = range.end.add(const Duration(days: 1));
      if (r.date.isBefore(range.start) || !r.date.isBefore(end)) return false;
    }
    return true;
  }

  List<BtkRecord> apply(List<BtkRecord> records) =>
      isActive ? records.where(matches).toList() : records;
}

final recordFilterProvider = StateProvider<RecordFilter>((ref) => const RecordFilter());

/// The groups in use, sorted. Records with no group are left out.
List<String> groupsIn(List<BtkRecord> records) {
  final groups = {for (final r in records) r.group.trim()}..remove('');
  return groups.toList()..sort();
}

extension RecordOnMap on BtkRecord {
  /// The record's place, or null unless it has two valid coordinates.
  LatLng? get mapPoint {
    final lat = latitude, lon = longitude;
    if (lat == null || lon == null) return null;
    if (lat.abs() > 90 || lon.abs() > 180) return null;
    return LatLng(lat, lon);
  }
}

/// The records whose place passes [contains], such as being in the map's view.
List<BtkRecord> recordsWithin(List<BtkRecord> records,
    {required bool Function(LatLng) contains}) {
  return records.where((r) {
    final point = r.mapPoint;
    return point != null && contains(point);
  }).toList();
}

const _groupPalette = [
  Color(0xFF1565C0),
  Color(0xFFC62828),
  Color(0xFF6A1B9A),
  Color(0xFFEF6C00),
  Color(0xFF00838F),
  Color(0xFF558B2F),
  Color(0xFFAD1457),
  Color(0xFF4E342E),
];

/// A colour that stays the same for a group's name on every device and run.
Color groupColor(String group) {
  var sum = 0;
  for (final unit in group.trim().codeUnits) {
    sum = (sum * 31 + unit) & 0x7fffffff;
  }
  return _groupPalette[sum % _groupPalette.length];
}
