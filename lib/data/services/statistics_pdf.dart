import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/records/domain/record_filter.dart';
import '../../features/stats/domain/geomass_analytics.dart';
import '../../features/stats/domain/mass_chart_data.dart';
import '../../features/stats/domain/record_comparison.dart';
import '../../features/stats/domain/results_export.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/btk_record.dart';

const _chartHeight = 150.0;

// Below this much room a table's title would sit alone at the foot of a page.
const _tableStartSpace = 90.0;

// A column gets room for its longest word, so it doesn't break mid-word, up to
// this many characters.
const _longestWord = 20;

// The bundled fonts can't draw these, and they'd print as black boxes.
String _printable(String s) => s.replaceAll('→', '>').replaceAll('≈', '~');

String _shown(Object? cell) => cell == null ? '' : _printable('$cell').trim();

/// A column the records left empty only takes room from the others.
ResultTable _withoutEmptyColumns(ResultTable t) {
  bool isEmpty(int c) => t.rows.every((row) {
    final text = _shown(row[c]);
    return text.isEmpty || text == '—';
  });
  final kept = [
    for (var c = 0; c < t.header.length; c++)
      if (!isEmpty(c)) c,
  ];
  return ResultTable(
    t.title,
    [for (final c in kept) t.header[c]],
    [
      for (final row in t.rows) [for (final c in kept) row[c]],
    ],
  );
}

Map<int, pw.TableColumnWidth> _columnWidths(ResultTable t) {
  int wordOf(Object? cell) => _shown(
    cell,
  ).split(RegExp(r'\s+')).fold(0, (longest, word) => word.length > longest ? word.length : longest);
  return {
    for (var c = 0; c < t.header.length; c++)
      c: pw.FlexColumnWidth(
        [
              wordOf(t.header[c]),
              for (final row in t.rows) wordOf(row[c]),
            ].reduce((a, b) => a > b ? a : b).clamp(1, _longestWord).toDouble() +
            1,
      ),
  };
}

/// What Statistics shows, as a report: the same tables as the CSV, plus one dot
/// chart per mass. As on screen there's no trend line, and fewer than two points
/// draws no chart.
Future<Uint8List> buildStatisticsPdf({
  required List<BtkRecord> records,
  required int totalRecords,
  required RecordFilter filter,
  required int bandStep,
  required AppLocalizations l10n,
  required DateTime now,
}) async {
  final font = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansGeorgian-Regular.ttf'));

  pw.TextStyle style({double size = 9, PdfColor? color}) => pw.TextStyle(
    font: font,
    // The Georgian font has no superscripts, which print as black boxes.
    fontFallback: [pw.Font.helvetica()],
    fontSize: size,
    color: color,
  );

  pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
    child: pw.Text(text, style: style(size: 11)),
  );

  pw.Widget table(ResultTable t) => pw.TableHelper.fromTextArray(
    headers: t.header.map(_shown).toList(),
    data: [
      for (final row in t.rows) [for (final c in row) c == null ? '—' : _shown(c)],
    ],
    headerStyle: style(size: 7),
    cellStyle: style(size: 7),
    cellPadding: const pw.EdgeInsets.all(2),
    columnWidths: _columnWidths(t),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
  );

  pw.Widget chart(ChartSeries series, String axisLabel) {
    final points = series.points;
    final xs = points.map((p) => p.x);
    final maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final axisStyle = style(size: 7);
    String format(num v) => shownNumber(v.toDouble());
    return pw.Column(
      children: [
        pw.SizedBox(
          height: _chartHeight,
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis(
                niceTicks(
                  xs.reduce((a, b) => a < b ? a : b),
                  xs.reduce((a, b) => a > b ? a : b),
                  minStep: 1,
                ),
                format: format,
                textStyle: axisStyle,
              ),
              yAxis: pw.FixedAxis(
                niceTicks(0, maxY == 0 ? 1 : maxY),
                format: format,
                textStyle: axisStyle,
                divisions: true,
                divisionsColor: PdfColors.grey300,
              ),
            ),
            datasets: [
              pw.PointDataSet(
                data: [for (final p in points) pw.PointChartValue(p.x, p.y)],
                pointSize: 3,
                color: PdfColors.green800,
              ),
            ],
          ),
        ),
        pw.Text(axisLabel, style: axisStyle),
      ],
    );
  }

  List<pw.Widget> chartsOf(GeomassComponent c) {
    final byAltitude = chartSeries(records, c, ChartAxis.altitude);
    final byYear = chartSeries(records, c, ChartAxis.date);
    final drawAltitude = byAltitude.points.length >= 2;
    final drawYear = byYear.points.length >= 2;
    if (!drawAltitude && !drawYear) return [];
    // Kept whole, so a chart's title and notes stay on its page.
    return [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8, bottom: 2),
            child: pw.Text(c.label(l10n), style: style()),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: drawAltitude ? chart(byAltitude, l10n.altitudeM) : pw.SizedBox()),
              pw.SizedBox(width: 12),
              pw.Expanded(child: drawYear ? chart(byYear, l10n.statsYear) : pw.SizedBox()),
            ],
          ),
          if (byAltitude.noAltitude > 0)
            pw.Text(
              l10n.statsChartNoAltitude(byAltitude.noAltitude),
              style: style(size: 7, color: PdfColors.grey700),
            ),
          if (byYear.unreadable > 0)
            pw.Text(
              l10n.statsChartUnreadable(byYear.unreadable),
              style: style(size: 7, color: PdfColors.grey700),
            ),
        ],
      ),
    ];
  }

  final charts = geomassComponents.expand(chartsOf).toList();
  final cover = resultCover(
    records: records,
    totalRecords: totalRecords,
    filter: filter,
    l10n: l10n,
    now: now,
  );

  final doc = pw.Document(theme: pw.ThemeData.withFont(base: font));
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: style(size: 7, color: PdfColors.grey700),
        ),
      ),
      build: (_) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.green800,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            cover.first.map((c) => '$c').join('   '),
            style: style(size: 13, color: PdfColors.white),
          ),
        ),
        pw.SizedBox(height: 6),
        for (final line in cover.skip(1))
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(line.map(_shown).join(': '), style: style()),
          ),
        if (charts.isNotEmpty) ...[
          heading(l10n.statsChart),
          pw.Text(l10n.statsChartNote, style: style(size: 7, color: PdfColors.grey700)),
          ...charts,
        ],
        for (final t in resultTables(records: records, bandStep: bandStep, l10n: l10n).map(
          _withoutEmptyColumns,
        )) ...[pw.NewPage(freeSpace: _tableStartSpace), heading(_printable(t.title)), table(t)],
      ],
    ),
  );
  return doc.save();
}
