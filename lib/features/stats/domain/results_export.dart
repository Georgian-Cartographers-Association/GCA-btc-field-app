import '../../../l10n/generated/app_localizations.dart';
import '../../../models/btk_record.dart';
import '../../records/domain/record_filter.dart';
import 'geomass_analytics.dart';
import 'group_analytics.dart';
import 'record_analytics.dart';
import 'record_comparison.dart';

const _missing = '';

// A spreadsheet runs a cell starting with one of these as a formula, and a name
// can come from an imported file. A plain negative number is left alone.
String _safe(String s) =>
    RegExp(r'^[=+@\t\r]|^-(?!\d)').hasMatch(s) ? "'$s" : s;

String _cell(Object? value) {
  final text = value == null ? _missing : _safe('$value');
  return '"${text.replaceAll('"', '""')}"';
}

String _totalCell(RowTotal? t) {
  if (t == null) return _missing;
  final v = t.value;
  return v == null ? compareUnreadable : shownNumber(v);
}

/// What Statistics shows, as a CSV for a spreadsheet, with what it covers stated
/// at the top. It holds the same counts as the screen and no conclusions.
String buildResultsCsv({
  required List<BtkRecord> records,
  required int totalRecords,
  required RecordFilter filter,
  required int bandStep,
  required AppLocalizations l10n,
  required DateTime now,
}) {
  final rows = <List<Object?>>[];

  void section(String title, List<Object?> header, List<List<Object?>> body) {
    if (body.isEmpty) return;
    rows
      ..add([])
      ..add([title])
      ..add(header)
      ..addAll(body);
  }

  void freq(String title, List<MapEntry<String, int>> entries) => section(
        title,
        [title, l10n.statsTierRecords],
        [for (final e in entries) [e.key, e.value]],
      );

  List<List<Object?>> groupRows(List<RecordGroup> groups, String unlabelled) => [
        for (final g in groups)
          [
            g.label ?? unlabelled,
            g.records,
            g.species,
            for (final m in g.masses) m.text,
          ],
      ];

  rows
    ..add([l10n.statistics, shortDate(now)])
    ..add([l10n.statsExportCovers(records.length, totalRecords)]);
  if (filter.groups.isNotEmpty) {
    rows.add([
      l10n.recordGroup,
      filter.groups.map((g) => g.isEmpty ? l10n.noGroup : g).join(', '),
    ]);
  }
  final dates = filter.dates;
  if (dates != null) {
    rows.add([l10n.date, '${shortDate(dates.start)} – ${shortDate(dates.end)}']);
  }
  if (filter.unfinishedOnly) rows.add([l10n.filterUnfinished]);
  rows
    ..add([l10n.statsExportNote])
    ..add([l10n.compareLegend]);

  final massHeaders = [for (final c in geomassComponents) c.label(l10n)];

  section(
    l10n.statsExportRecords,
    ['ID', l10n.name, l10n.date, l10n.altitudeM, ...massHeaders],
    [
      for (final r in records)
        [
          r.id,
          r.name,
          shortDate(r.date),
          r.altitude == null ? null : shownNumber(r.altitude!),
          for (final c in geomassComponents) _totalCell(c.total(r)),
        ],
    ],
  );

  final analytics = RecordAnalytics.of(records);
  section(
    l10n.statsVegStructure,
    [l10n.vegTier, l10n.statsTierRecords, l10n.statsTierSpecies, l10n.vegHeightM],
    [
      for (final t in analytics.tiers)
        [
          t.tier.isEmpty ? l10n.statsNoTier : t.tier,
          t.records,
          t.species,
          rangeText(t.minHeight, t.maxHeight, t.unreadableHeights),
        ],
    ],
  );
  freq(l10n.statsSpeciesFrequency, analytics.species);
  freq(l10n.statsHorizonFrequency, analytics.horizons);
  freq(l10n.statsHorizonOrders, analytics.horizonOrders);

  final geomass = GeomassAnalytics.of(records);
  section(
    l10n.statsGeomassTotals,
    [l10n.statsGeomassComponent, l10n.statsTierRecords, l10n.statsGeomassRange],
    [
      for (final c in geomass.components)
        [c.component.label(l10n), c.records, c.totals.text],
    ],
  );
  section(
    l10n.statsDepthLayers,
    [
      l10n.statsDepthLayer,
      l10n.statsTierRecords,
      for (final c in layerColumns) c.label(l10n),
    ],
    [
      for (final layer in geomass.layers)
        [
          layer.text ?? l10n.statsDepthUnknown,
          layer.records,
          for (final v in layer.values) v.text,
        ],
    ],
  );

  final groupHeader = [l10n.statsTierRecords, l10n.statsTierSpecies, ...massHeaders];
  if (records.any((r) => r.altitude != null)) {
    section(
      '${l10n.statsAltitudeBands}, $bandStep',
      [l10n.statsAltitudeBand, ...groupHeader],
      groupRows(altitudeBands(records, bandStep), l10n.statsNoAltitude),
    );
  }
  section(
    l10n.statsByYear,
    [l10n.statsYear, ...groupHeader],
    groupRows(yearGroups(records), ''),
  );
  section(
    l10n.statsRepeatedPlaces,
    [l10n.location, l10n.statsTierRecords, l10n.date, l10n.date],
    [
      for (final p in repeatedPlaces(records))
        [p.place, p.records.length, shortDate(p.first), shortDate(p.last)],
    ],
  );

  return rows.map((row) => row.map(_cell).join(',')).join('\r\n');
}
