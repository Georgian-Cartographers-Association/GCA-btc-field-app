import '../l10n/localized_text.dart';
import 'btk_record.dart';
import 'measure.dart';

/// The form's sections, in tab order.
enum FormSection { basic, physGeo, vegetation, soil, geomass, vertStruct }

/// Something in a record worth a second look. Notes never stop a record from
/// being saved, because field work often fills a record in several sittings.
class QualityNote {
  final FormSection section;
  final LocalizedText message;

  const QualityNote(this.section, this.message);
}

bool _has(String s) => s.trim().isNotEmpty;

extension RecordQuality on BtkRecord {
  bool get hasLocation => _has(location);
  bool get hasCoordinates => latitude != null && longitude != null;

  /// A record is unfinished until it says where it was made.
  bool get isUnfinished => !hasLocation || !hasCoordinates;

  bool isFilled(FormSection section) {
    switch (section) {
      case FormSection.basic:
        return !isUnfinished;
      case FormSection.physGeo:
        return [
          geologicalFormation,
          reliefType,
          morphologicalDesc,
          geomorphProcesses,
          migrationRegime,
          moistureDegree,
        ].any(_has);
      case FormSection.vegetation:
        return vegetation.any((r) => !isBlankRow(r.toJson()));
      case FormSection.soil:
        return [soilTypeName, soilProfileDesc, geohorizonIndex, soilSurfaceFormation]
                .any(_has) ||
            soilHorizons.any((r) => !isBlankRow(r.toJson()));
      case FormSection.geomass:
        return _has(experimentPlotSize) ||
            geomasses.any((r) => !isBlankRow(r.toJson())) ||
            treePhytomass.any((r) => !isBlankRow(r.toJson()));
      case FormSection.vertStruct:
        return [vertStructTypeName, vertStructIndex, vertStructHeight, vertStructDesc]
            .any(_has);
    }
  }

  List<QualityNote> qualityNotes({DateTime? now}) {
    final notes = <QualityNote>[];

    void note(FormSection section, LocalizedText message, [int? row]) {
      notes.add(QualityNote(
        section,
        row == null ? message : (l10n) => l10n.qualityRow(row + 1, message(l10n)),
      ));
    }

    void measure(FormSection section, MeasureSpec spec, String text,
        LocalizedText label, [int? row]) {
      switch (spec.check(text)) {
        case MeasureIssue.unreadable:
          note(section, (l10n) => l10n.qualityUnreadable(label(l10n)), row);
        case MeasureIssue.outOfRange:
          note(section, (l10n) => l10n.qualityOutOfRange(label(l10n)), row);
        case null:
          break;
      }
    }

    void dryVsWet(double? dry, double? wet, LocalizedText label, int row) {
      if (dry != null && wet != null && dry > wet) {
        note(FormSection.geomass, (l10n) => l10n.qualityDryAboveWet(label(l10n)), row);
      }
    }

    // A total can only be compared once every part is known.
    void total(List<double?> parts, double? value, LocalizedText label, int row) {
      if (value == null || parts.contains(null)) return;
      final sum = parts.fold<double>(0, (a, b) => a + b!);
      final allowed = value * 0.05 > 0.01 ? value * 0.05 : 0.01;
      if ((sum - value).abs() > allowed) {
        final shown = double.parse(sum.toStringAsFixed(2)).toString();
        note(FormSection.geomass,
            (l10n) => l10n.qualityTotalMismatch(label(l10n), shown), row);
      }
    }

    const basic = FormSection.basic;
    if (!hasLocation) note(basic, (l10n) => l10n.qualityMissingLocation);
    if (!hasCoordinates) {
      note(basic, (l10n) => l10n.qualityMissingCoords);
    } else if (latitude!.abs() > 90 || longitude!.abs() > 180) {
      note(basic, (l10n) => l10n.qualityBadCoords);
    }
    final accuracy = coordAccuracy;
    if (accuracy != null && accuracy > 50) {
      note(basic, (l10n) => l10n.qualityLowAccuracy(accuracy.round()));
    }
    if (date.isAfter((now ?? DateTime.now()).add(const Duration(days: 1)))) {
      note(basic, (l10n) => l10n.qualityFutureDate);
    }

    for (var i = 0; i < vegetation.length; i++) {
      measure(FormSection.vegetation, Measures.vegHeight, vegetation[i].height,
          (l10n) => l10n.vegHeightM, i);
    }

    const geo = FormSection.geomass;
    for (var i = 0; i < geomasses.length; i++) {
      final g = geomasses[i];
      measure(geo, Measures.depth, g.depth, (l10n) => l10n.gmDepth, i);
      measure(geo, Measures.soilBulkDensity, g.pedomassBulk, (l10n) => l10n.gmPedBulk, i);
      measure(geo, Measures.geomass, g.pedomassQty, (l10n) => l10n.gmPedQty, i);
      measure(geo, Measures.geomass, g.lithomassQty, (l10n) => l10n.gmLithQty, i);
      measure(geo, Measures.rockDensity, g.lithomassDensity, (l10n) => l10n.gmLithDens, i);
      measure(geo, Measures.geomass, g.hydromassQty, (l10n) => l10n.gmHydQty, i);
      measure(geo, Measures.plain, g.hydromassWet, (l10n) => l10n.gmHydWet, i);
      measure(geo, Measures.plain, g.hydromassDry, (l10n) => l10n.gmHydDry, i);
      measure(geo, Measures.geomass, g.phytomassWet, (l10n) => l10n.gmPhytWet, i);
      measure(geo, Measures.geomass, g.phytomassDry, (l10n) => l10n.gmPhytDry, i);
      dryVsWet(g.phytomassDryValue, g.phytomassWetValue, (l10n) => l10n.gmPhytDry, i);
    }

    if (depthUnit.isEmpty && geomasses.any((g) => _has(g.depth))) {
      note(geo, (l10n) => l10n.qualityDepthUnitMissing);
    }

    measure(geo, Measures.plotSize, experimentPlotSize, (l10n) => l10n.experimentPlotSize);

    for (var i = 0; i < treePhytomass.length; i++) {
      final t = treePhytomass[i];
      measure(geo, Measures.woodDensity, t.bulkDensity, (l10n) => l10n.tpVolume, i);
      measure(geo, Measures.geomass, t.wetWood, (l10n) => l10n.tpWetWood, i);
      measure(geo, Measures.geomass, t.wetLeaves, (l10n) => l10n.tpWetLeaves, i);
      measure(geo, Measures.geomass, t.wetBranches, (l10n) => l10n.tpWetBranches, i);
      measure(geo, Measures.geomass, t.wetRoots, (l10n) => l10n.tpWetRoots, i);
      measure(geo, Measures.geomass, t.wetTotal, (l10n) => l10n.tpWetTotal, i);
      measure(geo, Measures.geomass, t.dryWood, (l10n) => l10n.tpDryWood, i);
      measure(geo, Measures.geomass, t.dryLeaves, (l10n) => l10n.tpDryLeaves, i);
      measure(geo, Measures.geomass, t.dryBranches, (l10n) => l10n.tpDryBranches, i);
      measure(geo, Measures.geomass, t.dryRoots, (l10n) => l10n.tpDryRoots, i);
      measure(geo, Measures.geomass, t.dryTotal, (l10n) => l10n.tpDryTotal, i);
      dryVsWet(t.dryWoodValue, t.wetWoodValue, (l10n) => l10n.tpDryWood, i);
      dryVsWet(t.dryLeavesValue, t.wetLeavesValue, (l10n) => l10n.tpDryLeaves, i);
      dryVsWet(t.dryBranchesValue, t.wetBranchesValue, (l10n) => l10n.tpDryBranches, i);
      dryVsWet(t.dryRootsValue, t.wetRootsValue, (l10n) => l10n.tpDryRoots, i);
      dryVsWet(t.dryTotalValue, t.wetTotalValue, (l10n) => l10n.tpDryTotal, i);
      total([t.wetWoodValue, t.wetLeavesValue, t.wetBranchesValue, t.wetRootsValue],
          t.wetTotalValue, (l10n) => l10n.tpWetTotal, i);
      total([t.dryWoodValue, t.dryLeavesValue, t.dryBranchesValue, t.dryRootsValue],
          t.dryTotalValue, (l10n) => l10n.tpDryTotal, i);
    }

    measure(FormSection.vertStruct, Measures.vertHeight, vertStructHeight,
        (l10n) => l10n.vegHeightM);

    return notes;
  }
}

/// A table row with nothing typed in it.
bool isBlankRow(Map<String, dynamic> row) =>
    row.values.every((v) => v.toString().trim().isEmpty);
