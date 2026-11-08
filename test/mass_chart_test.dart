import 'package:btk_field_app/features/stats/domain/geomass_analytics.dart';
import 'package:btk_field_app/features/stats/domain/mass_chart_data.dart';
import 'package:btk_field_app/features/stats/ui/mass_chart.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BtkRecord _record(String name, {double? altitude, String pedomass = '', DateTime? date}) =>
    BtkRecord(id: name, date: date ?? DateTime(2026, 7, 1))
      ..name = name
      ..altitude = altitude
      ..geomasses = [GeomassRow(pedomassQty: pedomass)];

Widget _app(List<BtkRecord> records) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ListView(children: [MassChart(records: records)])),
    );

void main() {
  test('records that cannot be drawn are counted, those without the mass are not', () {
    final series = chartSeries([
      _record('drawn', altitude: 100, pedomass: '10'),
      _record('no altitude', pedomass: '10'),
      _record('unreadable', altitude: 100, pedomass: 'ბევრი'),
      _record('no mass', altitude: 100),
    ], geomassComponents.first, ChartAxis.altitude);
    expect(series.points.map((p) => p.record.name), ['drawn']);
    expect(series.noAltitude, 1);
    expect(series.unreadable, 1);
  });

  test('a record with no altitude can still be drawn against time', () {
    final series = chartSeries(
        [_record('A', pedomass: '10')], geomassComponents.first, ChartAxis.date);
    expect(series.points.single.x, closeTo(2026.5, 0.01));
    expect(series.noAltitude, 0);
  });

  test('ticks are round and cover the data', () {
    expect(niceTicks(0, 460.5), [0, 200, 400, 600]);
    expect(niceTicks(1880, 2050, minStep: 1), [1850, 1900, 1950, 2000, 2050]);
  });

  test('ticks survive a single value and respect the smallest step', () {
    expect(niceTicks(1880, 1880, minStep: 1), [1879, 1880, 1881]);
    expect(niceTicks(2026.4, 2026.6, minStep: 1), [2026, 2027]);
  });

  testWidgets('with too few points it says so and draws nothing', (tester) async {
    await tester.pumpWidget(_app([_record('A', altitude: 100, pedomass: '10')]));
    expect(find.textContaining('at least 2'), findsOneWidget);
    expect(find.textContaining('Tap a dot'), findsNothing);
  });

  testWidgets('without any geomass it takes no space', (tester) async {
    await tester.pumpWidget(_app([_record('A')]));
    expect(find.textContaining('Chart'), findsNothing);
  });

  testWidgets('tapping a dot names its record, and missing ones are reported', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app([
      _record('Low', altitude: 1000, pedomass: '100'),
      _record('High', altitude: 2000, pedomass: '200'),
      _record('Lost', pedomass: '50'),
    ]));
    expect(find.textContaining('1 records not shown: no altitude'), findsOneWidget);

    // The top right dot: ticks run to 2000 and 200, in a 240 high plot.
    final plot = tester.getTopLeft(find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter != null && w.painter.runtimeType.toString() == '_PlotPainter'));
    await tester.tapAt(plot + const Offset(400 - 12, 8));
    await tester.pump();
    expect(find.textContaining('High · 2000 m · 200'), findsOneWidget);

    // Switching the axis clears the choice, and the lost record comes back.
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(find.textContaining('High ·'), findsNothing);
    expect(find.textContaining('no altitude'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
