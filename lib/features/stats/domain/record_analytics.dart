import '../../../models/btk_record.dart';
import '../../../models/record_quality.dart';
import 'record_comparison.dart';

/// What was recorded in one vegetation tier across several records. An empty
/// [tier] holds the filled rows that name no tier.
class TierSummary {
  final String tier;
  final int records;
  final int species;
  final double? minHeight;
  final double? maxHeight;

  /// Heights that were typed but can't be read, left out of the range.
  final int unreadableHeights;

  const TierSummary({
    required this.tier,
    required this.records,
    required this.species,
    this.minHeight,
    this.maxHeight,
    this.unreadableHeights = 0,
  });
}

/// Counts over stored values only. Nothing is averaged or inferred, so the
/// figures stay true however few records there are.
class RecordAnalytics {
  final int recordsWithVegetation;
  final List<TierSummary> tiers;

  /// Species and the number of records naming each, most frequent first.
  final List<MapEntry<String, int>> species;

  final int recordsWithHorizons;

  /// Horizons and the number of records holding each, most frequent first.
  final List<MapEntry<String, int>> horizons;

  /// Horizon sequences and the number of records with each, most frequent first.
  final List<MapEntry<String, int>> horizonOrders;

  const RecordAnalytics({
    required this.recordsWithVegetation,
    required this.tiers,
    required this.species,
    required this.recordsWithHorizons,
    required this.horizons,
    required this.horizonOrders,
  });

  factory RecordAnalytics.of(List<BtkRecord> records) {
    final vegetated = [
      for (final r in records)
        r.vegetation.where((v) => !isBlankRow(v.toJson())).toList(),
    ].where((rows) => rows.isNotEmpty).toList();
    final orders = records.map(horizonLabels).where((l) => l.isNotEmpty).toList();

    return RecordAnalytics(
      recordsWithVegetation: vegetated.length,
      tiers: _tiers(vegetated),
      species: _countPerRecord(
          vegetated.map((rows) => rows.expand((v) => speciesNames(v.species)))),
      recordsWithHorizons: orders.length,
      horizons: _sorted(_tally(orders.expand((l) => l.toSet()))),
      horizonOrders: _sorted(_tally(orders.map(horizonOrder))),
    );
  }

  bool get hasVegetation => recordsWithVegetation > 0;
  bool get hasHorizons => recordsWithHorizons > 0;
}

/// The horizon names of [r] from top to bottom. A filled row with no name shows
/// as [compareUnreadable], so the sequence doesn't look complete without it.
List<String> horizonLabels(BtkRecord r) => [
      for (final h in r.soilHorizons)
        if (!isBlankRow(h.toJson()))
          h.horizon.trim().isEmpty ? compareUnreadable : tidyText(h.horizon),
    ];

String horizonOrder(List<String> labels) => labels.join(' → ');

/// The tiers named in [r], in the order they were entered.
List<String> tierLabels(BtkRecord r) => _firstSpellings(
    r.vegetation.map((v) => tidyText(v.tier)).where((t) => t.isNotEmpty)).toList();

String tidyText(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

// Latin names may differ in case only, as "fagus" and "Fagus". Horizons are not
// folded, because case carries meaning there: "Ah" isn't "AH".
String nameKey(String s) => s.toLowerCase();

Iterable<String> _firstSpellings(Iterable<String> names) {
  final seen = <String, String>{};
  for (final n in names) {
    seen.putIfAbsent(nameKey(n), () => n);
  }
  return seen.values;
}

Iterable<String> speciesNames(String cell) =>
    cell.split(RegExp(r'[,;\n]')).map(tidyText).where((s) => s.isNotEmpty);

Map<String, int> _tally(Iterable<String> values) {
  final counts = <String, int>{};
  for (final v in values) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  return counts;
}

List<MapEntry<String, int>> _sorted(Map<String, int> counts) =>
    counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

/// How many records name each value, under the first spelling met.
List<MapEntry<String, int>> _countPerRecord(Iterable<Iterable<String>> perRecord) {
  final shown = <String, String>{};
  final counts = <String, int>{};
  for (final names in perRecord) {
    for (final key in names.map(nameKey).toSet()) {
      counts[key] = (counts[key] ?? 0) + 1;
    }
    for (final n in names) {
      shown.putIfAbsent(nameKey(n), () => n);
    }
  }
  return _sorted({for (final e in counts.entries) shown[e.key]!: e.value});
}

List<TierSummary> _tiers(List<List<VegetationRow>> vegetated) {
  final rowsByTier = <String, List<VegetationRow>>{};
  final recordsByTier = <String, int>{};
  final shown = <String, String>{};
  for (final rows in vegetated) {
    final inThisRecord = <String>{};
    for (final v in rows) {
      final tier = tidyText(v.tier);
      final key = nameKey(tier);
      shown.putIfAbsent(key, () => tier);
      rowsByTier.putIfAbsent(key, () => []).add(v);
      inThisRecord.add(key);
    }
    for (final key in inThisRecord) {
      recordsByTier[key] = (recordsByTier[key] ?? 0) + 1;
    }
  }

  final summaries = [
    for (final e in rowsByTier.entries)
      _tierSummary(shown[e.key]!, recordsByTier[e.key]!, e.value),
  ];
  // The rows without a tier go last.
  return summaries
    ..sort((a, b) {
      if (a.tier.isEmpty != b.tier.isEmpty) return a.tier.isEmpty ? 1 : -1;
      return a.tier.compareTo(b.tier);
    });
}

TierSummary _tierSummary(String tier, int records, List<VegetationRow> rows) {
  final filled = rows.where((v) => v.height.trim().isNotEmpty).toList();
  final heights = filled.map((v) => v.heightValue).whereType<double>().toList();
  return TierSummary(
    tier: tier,
    records: records,
    species: rows.expand((v) => speciesNames(v.species)).map(nameKey).toSet().length,
    minHeight: heights.isEmpty ? null : heights.reduce((a, b) => a < b ? a : b),
    maxHeight: heights.isEmpty ? null : heights.reduce((a, b) => a > b ? a : b),
    unreadableHeights: filled.length - heights.length,
  );
}
