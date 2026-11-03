import '../../../l10n/localized_text.dart';
import '../../../models/btk_record.dart';
import '../../../models/record_quality.dart';
import 'record_comparison.dart';

/// The sum of a record's rows. A null [value] means a filled cell couldn't be
/// read, because a sum that silently skipped one would look complete.
class RowTotal {
  final double? value;
  const RowTotal(this.value);
}

/// Null when none of [rows] is filled in.
RowTotal? totalOf<T>(
    List<T> rows, String Function(T) text, double? Function(T) value) {
  final filled = rows.where((r) => text(r).trim().isNotEmpty).toList();
  if (filled.isEmpty) return null;
  var total = 0.0;
  for (final r in filled) {
    final v = value(r);
    if (v == null) return const RowTotal(null);
    total += v;
  }
  return RowTotal(total);
}

/// One mass that a record can hold a total of, in tonnes per hectare.
class GeomassComponent {
  final LocalizedText label;
  final RowTotal? Function(BtkRecord) total;

  const GeomassComponent(this.label, this.total);
}

final geomassComponents = <GeomassComponent>[
  GeomassComponent((l) => l.comparePedomass,
      (r) => totalOf(r.geomasses, (g) => g.pedomassQty, (g) => g.pedomassQtyValue)),
  GeomassComponent((l) => l.compareLithomass,
      (r) => totalOf(r.geomasses, (g) => g.lithomassQty, (g) => g.lithomassQtyValue)),
  GeomassComponent((l) => l.compareHydromass,
      (r) => totalOf(r.geomasses, (g) => g.hydromassQty, (g) => g.hydromassQtyValue)),
  GeomassComponent((l) => l.comparePhytomassWet,
      (r) => totalOf(r.geomasses, (g) => g.phytomassWet, (g) => g.phytomassWetValue)),
  GeomassComponent((l) => l.comparePhytomassDry,
      (r) => totalOf(r.geomasses, (g) => g.phytomassDry, (g) => g.phytomassDryValue)),
  GeomassComponent((l) => l.compareTreeWet,
      (r) => totalOf(r.treePhytomass, (t) => t.wetTotal, (t) => t.wetTotalValue)),
  GeomassComponent((l) => l.compareTreeDry,
      (r) => totalOf(r.treePhytomass, (t) => t.dryTotal, (t) => t.dryTotalValue)),
];

/// A mass as a depth layer table shows it.
class LayerColumn {
  final LocalizedText label;
  final String Function(GeomassRow) text;
  final double? Function(GeomassRow) value;

  const LayerColumn(this.label, this.text, this.value);
}

final layerColumns = <LayerColumn>[
  LayerColumn((l) => l.pedomass, (g) => g.pedomassQty, (g) => g.pedomassQtyValue),
  LayerColumn((l) => l.lithomass, (g) => g.lithomassQty, (g) => g.lithomassQtyValue),
  LayerColumn((l) => l.hydromass, (g) => g.hydromassQty, (g) => g.hydromassQtyValue),
  LayerColumn((l) => l.statsPhytomassWet, (g) => g.phytomassWet, (g) => g.phytomassWetValue),
  LayerColumn((l) => l.statsPhytomassDry, (g) => g.phytomassDry, (g) => g.phytomassDryValue),
];

/// Lowest and highest of the values added, with unreadable ones counted apart.
class ValueSpan {
  double? min;
  double? max;
  int unreadable = 0;

  void add(double? v) {
    if (v == null) {
      unreadable++;
      return;
    }
    min = min == null || v < min! ? v : min;
    max = max == null || v > max! ? v : max;
  }

  void addAll(Iterable<double?> values) => values.forEach(add);

  String? get text => rangeText(min, max, unreadable);
}

class ComponentSummary {
  final GeomassComponent component;
  final int records;
  final ValueSpan totals;

  const ComponentSummary(this.component, this.records, this.totals);
}

/// The rows of one depth range, in centimetres. Null [from] and [to] hold the
/// rows whose depth is blank, unreadable or has no unit.
class DepthLayer {
  final double? from;
  final double? to;
  final int records;

  /// One span for each of [layerColumns].
  final List<ValueSpan> values;

  const DepthLayer(this.from, this.to, this.records, this.values);

  bool get isKnown => from != null;
  String? get text =>
      isKnown ? '${shownNumber(from!)}–${shownNumber(to!)}' : null;
}

/// Only stored values are counted. Layers group by the exact range entered, so
/// "0-20" and "0-25" stay apart rather than being merged by a guess.
class GeomassAnalytics {
  final int recordsWithData;
  final List<ComponentSummary> components;
  final List<DepthLayer> layers;

  const GeomassAnalytics(this.recordsWithData, this.components, this.layers);

  factory GeomassAnalytics.of(List<BtkRecord> records) {
    final withData = records.where((r) =>
        r.geomasses.any((g) => !isBlankRow(g.toJson())) ||
        r.treePhytomass.any((t) => !isBlankRow(t.toJson())));
    return GeomassAnalytics(
      withData.length,
      _components(withData),
      _layers(withData),
    );
  }

  bool get hasData => recordsWithData > 0;
}

List<ComponentSummary> _components(Iterable<BtkRecord> records) {
  final result = <ComponentSummary>[];
  for (final c in geomassComponents) {
    final totals = records.map(c.total).whereType<RowTotal>().toList();
    if (totals.isEmpty) continue;
    result.add(ComponentSummary(
        c, totals.length, ValueSpan()..addAll(totals.map((t) => t.value))));
  }
  return result;
}

List<DepthLayer> _layers(Iterable<BtkRecord> records) {
  final ranges = <String, ({double? from, double? to})>{};
  final recordIds = <String, Set<String>>{};
  final spans = <String, List<ValueSpan>>{};
  const unknown = '';
  for (final r in records) {
    for (final g in r.geomasses.where((g) => !isBlankRow(g.toJson()))) {
      final range = r.depthRangeCm(g);
      // Text keys, since metres scaled up can land on 20.000000000000004.
      final key = range == null
          ? unknown
          : '${shownNumber(range.from)}-${shownNumber(range.to)}';
      ranges[key] = (from: range?.from, to: range?.to);
      recordIds.putIfAbsent(key, () => {}).add(r.id);
      final row = spans.putIfAbsent(
          key, () => [for (final _ in layerColumns) ValueSpan()]);
      for (var i = 0; i < layerColumns.length; i++) {
        final column = layerColumns[i];
        if (column.text(g).trim().isNotEmpty) row[i].add(column.value(g));
      }
    }
  }

  final layers = [
    for (final key in ranges.keys)
      DepthLayer(ranges[key]!.from, ranges[key]!.to, recordIds[key]!.length, spans[key]!),
  ];
  // Rows of unknown depth go last.
  return layers
    ..sort((a, b) {
      if (a.isKnown != b.isKnown) return a.isKnown ? -1 : 1;
      if (!a.isKnown) return 0;
      final byFrom = a.from!.compareTo(b.from!);
      return byFrom != 0 ? byFrom : a.to!.compareTo(b.to!);
    });
}
