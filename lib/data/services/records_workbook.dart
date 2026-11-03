import 'dart:typed_data';

import '../../l10n/generated/app_localizations.dart';
import '../../models/btk_record.dart';
import '../../models/record_quality.dart';
import 'xlsx_writer.dart';

String _day(DateTime d) => d.toIso8601String().substring(0, 10);

// A value the app can read goes in as a number, for sums in the spreadsheet.
// Anything else stays as typed, so a value like "P" isn't lost.
Object? _value(String text, double? number) {
  if (text.trim().isEmpty) return null;
  return number ?? text;
}

Object? _text(String text) => text.trim().isEmpty ? null : text;

/// Every record's fields and tables, one sheet each. Table rows start with the
/// record's ID and name, so they can be joined back to the first sheet.
Uint8List buildRecordsWorkbook(List<BtkRecord> records, AppLocalizations l10n) {
  List<List<Object?>> rowsOf<T extends Object>(
    List<T> Function(BtkRecord) table,
    Map<String, dynamic> Function(T) json,
    List<Object?> Function(BtkRecord, T) cells,
  ) =>
      [
        for (final r in records)
          for (final row in table(r))
            if (!isBlankRow(json(row))) [r.id, r.name, ...cells(r, row)],
      ];

  final key = ['ID', l10n.name];
  String withUnit(String label, String unit) => '$label ($unit)';

  return buildXlsx([
    XlsxSheet(l10n.statsExportRecords, [
      ...key,
      l10n.date,
      l10n.recordGroup,
      l10n.latitude,
      l10n.longitude,
      l10n.altitudeM,
      l10n.aspectDeg,
      l10n.location,
      l10n.geologicalFormation,
      l10n.reliefType,
      l10n.morphologicalDesc,
      l10n.geomorphProcesses,
      l10n.migrationRegime,
      l10n.moistureDegree,
      l10n.soilTypeName,
      l10n.soilProfileDesc,
      l10n.geohorizonIndex,
      l10n.soilSurfaceFormation,
      l10n.experimentPlotSize,
      l10n.depthUnit,
      l10n.vertStructTypeName,
      l10n.vertStructIndex,
      l10n.vegHeightM,
      l10n.vertStructDesc,
    ], [
      for (final r in records)
        [
          r.id,
          _text(r.name),
          _day(r.date),
          _text(r.group),
          r.latitude,
          r.longitude,
          r.altitude,
          r.aspect,
          _text(r.location),
          _text(r.geologicalFormation),
          _text(r.reliefType),
          _text(r.morphologicalDesc),
          _text(r.geomorphProcesses),
          _text(r.migrationRegime),
          _text(r.moistureDegree),
          _text(r.soilTypeName),
          _text(r.soilProfileDesc),
          _text(r.geohorizonIndex),
          _text(r.soilSurfaceFormation),
          _text(r.experimentPlotSize),
          switch (r.depthUnit) {
            depthUnitCm => l10n.unitCm,
            depthUnitM => l10n.unitM,
            _ => null,
          },
          _text(r.vertStructTypeName),
          _text(r.vertStructIndex),
          _text(r.vertStructHeight),
          _text(r.vertStructDesc),
        ],
    ]),
    XlsxSheet(
      l10n.vegetation,
      [...key, l10n.vegTier, l10n.vegHeightM, l10n.vegDensity, l10n.vegPhenophase, l10n.species],
      rowsOf<VegetationRow>(
        (r) => r.vegetation,
        (v) => v.toJson(),
        (_, v) => [
          _text(v.tier),
          _value(v.height, v.heightValue),
          _text(v.density),
          _text(v.phenophase),
          _text(v.species),
        ],
      ),
    ),
    XlsxSheet(
      l10n.soilHorizons,
      [...key, l10n.horizonShort, l10n.soilHorizonDesc],
      rowsOf<SoilHorizonRow>(
        (r) => r.soilHorizons,
        (h) => h.toJson(),
        (_, h) => [_text(h.horizon), _text(h.description)],
      ),
    ),
    XlsxSheet(
      l10n.geomasses,
      [
        ...key,
        l10n.gmSection,
        l10n.gmDepth,
        l10n.exportDepthFromCm,
        l10n.exportDepthToCm,
        withUnit(l10n.gmPedBulk, l10n.unitGCm3),
        withUnit(l10n.gmPedQty, l10n.unitTHa),
        withUnit(l10n.gmLithQty, l10n.unitTHa),
        withUnit(l10n.gmLithDens, l10n.unitGCm3),
        withUnit(l10n.gmHydQty, l10n.unitTHa),
        l10n.gmHydWet,
        l10n.gmHydDry,
        withUnit(l10n.gmPhytWet, l10n.unitTHa),
        withUnit(l10n.gmPhytDry, l10n.unitTHa),
      ],
      rowsOf<GeomassRow>(
        (r) => r.geomasses,
        (g) => g.toJson(),
        (r, g) {
          final range = r.depthRangeCm(g);
          return [
            _text(g.section),
            _text(g.depth),
            range?.from,
            range?.to,
            _value(g.pedomassBulk, g.pedomassBulkValue),
            _value(g.pedomassQty, g.pedomassQtyValue),
            _value(g.lithomassQty, g.lithomassQtyValue),
            _value(g.lithomassDensity, g.lithomassDensityValue),
            _value(g.hydromassQty, g.hydromassQtyValue),
            _value(g.hydromassWet, g.hydromassWetValue),
            _value(g.hydromassDry, g.hydromassDryValue),
            _value(g.phytomassWet, g.phytomassWetValue),
            _value(g.phytomassDry, g.phytomassDryValue),
          ];
        },
      ),
    ),
    XlsxSheet(
      l10n.treePhytomass,
      [
        ...key,
        l10n.tpSpecies,
        withUnit(l10n.tpVolume, l10n.unitTM3),
        withUnit(l10n.tpWetWood, l10n.unitTHa),
        withUnit(l10n.tpWetLeaves, l10n.unitTHa),
        withUnit(l10n.tpWetBranches, l10n.unitTHa),
        withUnit(l10n.tpWetRoots, l10n.unitTHa),
        withUnit(l10n.tpWetTotal, l10n.unitTHa),
        withUnit(l10n.tpDryWood, l10n.unitTHa),
        withUnit(l10n.tpDryLeaves, l10n.unitTHa),
        withUnit(l10n.tpDryBranches, l10n.unitTHa),
        withUnit(l10n.tpDryRoots, l10n.unitTHa),
        withUnit(l10n.tpDryTotal, l10n.unitTHa),
      ],
      rowsOf<TreePhytomassRow>(
        (r) => r.treePhytomass,
        (t) => t.toJson(),
        (_, t) => [
          _text(t.species),
          _value(t.bulkDensity, t.bulkDensityValue),
          _value(t.wetWood, t.wetWoodValue),
          _value(t.wetLeaves, t.wetLeavesValue),
          _value(t.wetBranches, t.wetBranchesValue),
          _value(t.wetRoots, t.wetRootsValue),
          _value(t.wetTotal, t.wetTotalValue),
          _value(t.dryWood, t.dryWoodValue),
          _value(t.dryLeaves, t.dryLeavesValue),
          _value(t.dryBranches, t.dryBranchesValue),
          _value(t.dryRoots, t.dryRootsValue),
          _value(t.dryTotal, t.dryTotalValue),
        ],
      ),
    ),
  ]);
}
