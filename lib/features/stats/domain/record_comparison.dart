import '../../../l10n/localized_text.dart';
import '../../../models/btk_record.dart';
import '../../../models/record_quality.dart';

/// Shown for a value that was typed but can't be used, such as "ბევრი" in a
/// number field or a depth with no unit.
const compareUnreadable = '?';

/// One line of the comparison, with a value per record. A null value was not
/// filled in. Nothing is estimated, so every number comes from typed values.
class CompareRow {
  final FormSection section;
  final LocalizedText label;
  final List<String?> values;

  const CompareRow(this.section, this.label, this.values);

  bool get hasData => values.any((v) => v != null);
  bool get differs => values.toSet().length > 1;
}

// Web prints a whole double as "50" and native as "50.0", so both drop the ".0".
String _shown(double v) {
  final s = double.parse(v.toStringAsFixed(2)).toString();
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String? _text(String s) => s.trim().isEmpty ? null : s.trim();

/// The sum over [rows], unreadable if any filled value isn't a number, because
/// a sum that silently skipped one would look complete.
String? _sumRows<T>(
    List<T> rows, String Function(T) text, double? Function(T) value) {
  final filled = rows.where((r) => text(r).trim().isNotEmpty).toList();
  if (filled.isEmpty) return null;
  var total = 0.0;
  for (final r in filled) {
    final v = value(r);
    if (v == null) return compareUnreadable;
    total += v;
  }
  return _shown(total);
}

String? _deepestCm(BtkRecord r) {
  final filled = r.geomasses.where((g) => g.depth.trim().isNotEmpty).toList();
  if (filled.isEmpty) return null;
  var deepest = 0.0;
  for (final g in filled) {
    final range = r.depthRangeCm(g);
    if (range == null) return compareUnreadable;
    if (range.to > deepest) deepest = range.to;
  }
  return _shown(deepest);
}

String? _tallest(BtkRecord r) {
  final filled = r.vegetation.where((v) => v.height.trim().isNotEmpty).toList();
  if (filled.isEmpty) return null;
  var tallest = 0.0;
  for (final v in filled) {
    final height = v.heightValue;
    if (height == null) return compareUnreadable;
    if (height > tallest) tallest = height;
  }
  return _shown(tallest);
}

String? _count(int n) => n == 0 ? null : '$n';

/// Lines that are empty for every record are left out.
List<CompareRow> compareRecords(List<BtkRecord> records) {
  CompareRow row(FormSection section, LocalizedText label, String? Function(BtkRecord) read) =>
      CompareRow(section, label, records.map(read).toList());

  const basic = FormSection.basic;
  const phys = FormSection.physGeo;
  const veg = FormSection.vegetation;
  const soil = FormSection.soil;
  const geo = FormSection.geomass;
  const vert = FormSection.vertStruct;

  return [
    row(basic, (l) => l.date, (r) => r.date.toIso8601String().substring(0, 10)),
    row(basic, (l) => l.location, (r) => _text(r.location)),
    row(basic, (l) => l.recordGroup, (r) => _text(r.group)),
    row(basic, (l) => l.altitudeM, (r) => r.altitude == null ? null : _shown(r.altitude!)),
    row(phys, (l) => l.geologicalFormation, (r) => _text(r.geologicalFormation)),
    row(phys, (l) => l.reliefType, (r) => _text(r.reliefType)),
    row(phys, (l) => l.geomorphProcesses, (r) => _text(r.geomorphProcesses)),
    row(phys, (l) => l.migrationRegime, (r) => _text(r.migrationRegime)),
    row(phys, (l) => l.moistureDegree, (r) => _text(r.moistureDegree)),
    row(veg, (l) => l.compareVegRows,
        (r) => _count(r.vegetation.where((v) => !isBlankRow(v.toJson())).length)),
    row(veg, (l) => l.compareMaxHeight, _tallest),
    row(veg, (l) => l.species,
        (r) => _text(r.vegetation.map((v) => v.species.trim()).where((s) => s.isNotEmpty).join(', '))),
    row(soil, (l) => l.soilTypeName, (r) => _text(r.soilTypeName)),
    row(soil, (l) => l.geohorizonIndex, (r) => _text(r.geohorizonIndex)),
    row(soil, (l) => l.compareHorizons,
        (r) => _count(r.soilHorizons.where((h) => !isBlankRow(h.toJson())).length)),
    row(geo, (l) => l.compareDeepest, _deepestCm),
    row(geo, (l) => l.comparePedomass,
        (r) => _sumRows(r.geomasses, (g) => g.pedomassQty, (g) => g.pedomassQtyValue)),
    row(geo, (l) => l.compareLithomass,
        (r) => _sumRows(r.geomasses, (g) => g.lithomassQty, (g) => g.lithomassQtyValue)),
    row(geo, (l) => l.compareHydromass,
        (r) => _sumRows(r.geomasses, (g) => g.hydromassQty, (g) => g.hydromassQtyValue)),
    row(geo, (l) => l.comparePhytomassWet,
        (r) => _sumRows(r.geomasses, (g) => g.phytomassWet, (g) => g.phytomassWetValue)),
    row(geo, (l) => l.comparePhytomassDry,
        (r) => _sumRows(r.geomasses, (g) => g.phytomassDry, (g) => g.phytomassDryValue)),
    row(geo, (l) => l.compareTreeWet,
        (r) => _sumRows(r.treePhytomass, (t) => t.wetTotal, (t) => t.wetTotalValue)),
    row(geo, (l) => l.compareTreeDry,
        (r) => _sumRows(r.treePhytomass, (t) => t.dryTotal, (t) => t.dryTotalValue)),
    row(vert, (l) => l.vertStructTypeName, (r) => _text(r.vertStructTypeName)),
    row(vert, (l) => l.vertStructIndex, (r) => _text(r.vertStructIndex)),
    row(vert, (l) => l.vegHeightM, (r) => _text(r.vertStructHeight)),
  ].where((r) => r.hasData).toList();
}
