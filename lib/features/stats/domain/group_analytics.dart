import '../../../models/btk_record.dart';
import 'geomass_analytics.dart';
import 'record_analytics.dart';

/// Steps offered for altitude bands, in metres. These are equal bands and not
/// named altitude belts, whose limits differ by region and author.
const altitudeBandSteps = [100, 250, 500];

/// What a set of records holds, for one altitude band or one year. A null
/// [label] is the group of records with no altitude.
class RecordGroup {
  final String? label;
  final int records;
  final int species;

  /// One span for each of [geomassComponents], over per-record totals.
  final List<ValueSpan> masses;

  const RecordGroup(this.label, this.records, this.species, this.masses);
}

RecordGroup _group(String? label, List<BtkRecord> records) {
  final species = {
    for (final r in records)
      for (final v in r.vegetation) ...speciesNames(v.species).map(nameKey),
  };
  final masses = [
    for (final c in geomassComponents)
      ValueSpan()..addAll(records.map(c.total).whereType<RowTotal>().map((t) => t.value)),
  ];
  return RecordGroup(label, records.length, species.length, masses);
}

/// The indexes of [geomassComponents] that hold data in any of [groups], so a
/// table leaves out columns that would be empty all the way down.
List<int> usedMassColumns(List<RecordGroup> groups) => [
      for (var i = 0; i < geomassComponents.length; i++)
        if (groups.any((g) => g.masses[i].text != null)) i,
    ];

/// Equal bands from low to high, then the records with no altitude. Only bands
/// holding records are listed. A value on a limit belongs to the upper band.
List<RecordGroup> altitudeBands(List<BtkRecord> records, int step) {
  final byBand = <int, List<BtkRecord>>{};
  final noAltitude = <BtkRecord>[];
  for (final r in records) {
    final altitude = r.altitude;
    if (altitude == null) {
      noAltitude.add(r);
    } else {
      byBand.putIfAbsent((altitude / step).floor(), () => []).add(r);
    }
  }
  final bands = byBand.keys.toList()..sort();
  return [
    for (final b in bands) _group('${b * step}–${(b + 1) * step}', byBand[b]!),
    if (noAltitude.isNotEmpty) _group(null, noAltitude),
  ];
}

/// Years from earliest to latest, by the date of each record.
List<RecordGroup> yearGroups(List<BtkRecord> records) {
  final byYear = <int, List<BtkRecord>>{};
  for (final r in records) {
    byYear.putIfAbsent(r.date.year, () => []).add(r);
  }
  final years = byYear.keys.toList()..sort();
  return [for (final y in years) _group('$y', byYear[y]!)];
}

/// A place described on more than one day, with its records oldest first.
class RepeatedPlace {
  final String place;
  final List<BtkRecord> records;

  const RepeatedPlace(this.place, this.records);

  DateTime get first => records.first.date;
  DateTime get last => records.last.date;
}

/// Places are matched by the location text alone. Nearby coordinates would be a
/// guess, since two plots metres apart can be different complexes.
List<RepeatedPlace> repeatedPlaces(List<BtkRecord> records) {
  final byPlace = <String, List<BtkRecord>>{};
  for (final r in records) {
    final place = tidyText(r.location);
    if (place.isNotEmpty) byPlace.putIfAbsent(nameKey(place), () => []).add(r);
  }
  final places = [
    for (final rows in byPlace.values)
      if (rows.map((r) => shortDate(r.date)).toSet().length > 1)
        RepeatedPlace(
          tidyText(rows.first.location),
          [...rows]..sort((a, b) => a.date.compareTo(b.date)),
        ),
  ];
  return places..sort((a, b) => a.place.compareTo(b.place));
}

/// A record's day as the comparison shows it.
String shortDate(DateTime d) => d.toIso8601String().substring(0, 10);
