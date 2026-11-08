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

/// One table of results, for any report format. A null cell wasn't filled in.
class ResultTable {
  final String title;
  final List<Object?> header;
  final List<List<Object?>> rows;

  const ResultTable(this.title, this.header, this.rows);
}

/// What a report covers. The first line names it, and the rest say which records
/// are in it, by which filter, and that it holds no conclusions.
List<List<Object?>> resultCover({
  required List<BtkRecord> records,
  required int totalRecords,
  required RecordFilter filter,
  required AppLocalizations l10n,
  required DateTime now,
}) {
  final dates = filter.dates;
  return [
    [l10n.statistics, shortDate(now)],
    [l10n.statsExportCovers(records.length, totalRecords)],
    if (filter.groups.isNotEmpty)
      [
        l10n.recordGroup,
        filter.groups.map((g) => g.isEmpty ? l10n.noGroup : g).join(', '),
      ],
    if (dates != null)
      [l10n.date, '${shortDate(dates.start)} – ${shortDate(dates.end)}'],
    if (filter.unfinishedOnly) [l10n.filterUnfinished],
    [l10n.statsExportNote],
    [l10n.compareLegend],
  ];
}

/// The same counts as the screen, leaving out tables with nothing in them.
List<ResultTable> resultTables({
  required List<BtkRecord> records,
  required int bandStep,
  required AppLocalizations l10n,
}) {
  ResultTable freq(String title, String label, List<MapEntry<String, int>> entries) =>
      ResultTable(
        title,
        [label, l10n.statsTierRecords],
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

  final massHeaders = [for (final c in geomassComponents) c.label(l10n)];
  final analytics = RecordAnalytics.of(records);
  final geomass = GeomassAnalytics.of(records);
  final groupHeader = [l10n.statsTierRecords, l10n.statsTierSpecies, ...massHeaders];

  return [
    ResultTable(
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
    ),
    ResultTable(
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
    ),
    freq(l10n.statsSpeciesFrequency, l10n.species, analytics.species),
    freq(l10n.statsHorizonFrequency, l10n.horizonShort, analytics.horizons),
    freq(l10n.statsHorizonOrders, l10n.compareHorizonOrder, analytics.horizonOrders),
    ResultTable(
      l10n.statsGeomassTotals,
      [l10n.statsGeomassComponent, l10n.statsTierRecords, l10n.statsGeomassRange],
      [
        for (final c in geomass.components)
          [c.component.label(l10n), c.records, c.totals.text],
      ],
    ),
    ResultTable(
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
    ),
    if (records.any((r) => r.altitude != null))
      ResultTable(
        '${l10n.statsAltitudeBands}, $bandStep',
        [l10n.statsAltitudeBand, ...groupHeader],
        groupRows(altitudeBands(records, bandStep), l10n.statsNoAltitude),
      ),
    ResultTable(
      l10n.statsByYear,
      [l10n.statsYear, ...groupHeader],
      groupRows(yearGroups(records), ''),
    ),
    ResultTable(
      l10n.statsRepeatedPlaces,
      [l10n.location, l10n.statsTierRecords, l10n.statsFirstDate, l10n.statsLastDate],
      [
        for (final p in repeatedPlaces(records))
          [p.place, p.records.length, shortDate(p.first), shortDate(p.last)],
      ],
    ),
  ].where((t) => t.rows.isNotEmpty).toList();
}

/// What Statistics shows, as a CSV for a spreadsheet.
String buildResultsCsv({
  required List<BtkRecord> records,
  required int totalRecords,
  required RecordFilter filter,
  required int bandStep,
  required AppLocalizations l10n,
  required DateTime now,
}) {
  final rows = <List<Object?>>[
    ...resultCover(
      records: records,
      totalRecords: totalRecords,
      filter: filter,
      l10n: l10n,
      now: now,
    ),
    for (final t in resultTables(records: records, bandStep: bandStep, l10n: l10n)) ...[
      [],
      [t.title],
      t.header,
      ...t.rows,
    ],
  ];
  return rows.map((row) => row.map(_cell).join(',')).join('\r\n');
}
