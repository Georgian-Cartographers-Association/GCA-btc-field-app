import 'package:btk_field_app/features/stats/domain/record_comparison.dart';
import 'package:btk_field_app/features/stats/ui/compare_screen.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BtkRecord _record(String id) => BtkRecord(id: id, date: DateTime(2026, 7, 1));

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  List<String?> valuesOf(List<BtkRecord> records, String label) => compareRecords(records)
      .firstWhere((r) => r.label(l10n) == label)
      .values;

  test('lines empty for every record are left out', () {
    final labels = compareRecords([_record('A'), _record('B')]).map((r) => r.label(l10n));
    expect(labels, [l10n.date]);
  });

  test('a filled value beside an empty one counts as a difference', () {
    final a = _record('A')..altitude = 1200;
    final rows = compareRecords([a, _record('B')]);
    final altitude = rows.firstWhere((r) => r.label(l10n) == l10n.altitudeM);
    expect(altitude.values, ['1200', null]);
    expect(altitude.differs, isTrue);
  });

  test('equal values are not a difference', () {
    final rows = compareRecords([_record('A'), _record('B')]);
    expect(rows.single.differs, isFalse);
  });

  test('sums add the rows, and blank rows do not count as zero', () {
    final a = _record('A')
      ..geomasses = [
        GeomassRow(pedomassQty: '10,5'),
        GeomassRow(pedomassQty: '4,5 ტ/ჰა'),
        GeomassRow(),
      ];
    expect(valuesOf([a, _record('B')], l10n.comparePedomass), ['15', null]);
  });

  test('one unreadable value makes the whole sum unreadable', () {
    final a = _record('A')
      ..geomasses = [GeomassRow(pedomassQty: '10'), GeomassRow(pedomassQty: 'ბევრი')];
    expect(valuesOf([a, _record('B')], l10n.comparePedomass), [compareUnreadable, null]);
  });

  test('depths compare in centimetres, whatever unit each record uses', () {
    final metres = _record('A')
      ..depthUnit = depthUnitM
      ..geomasses = [GeomassRow(depth: '0-0,2'), GeomassRow(depth: '0,2-0,5')];
    final cm = _record('B')
      ..depthUnit = depthUnitCm
      ..geomasses = [GeomassRow(depth: '0-50')];
    expect(valuesOf([metres, cm], l10n.compareDeepest), ['50', '50']);
  });

  test('a depth with no unit stays unreadable rather than guessed', () {
    final old = _record('A')..geomasses = [GeomassRow(depth: '50')];
    expect(valuesOf([old, _record('B')], l10n.compareDeepest), [compareUnreadable, null]);
  });

  test('vegetation counts only filled rows and finds the tallest', () {
    final a = _record('A')
      ..vegetation = [
        VegetationRow(height: '12', species: 'Fagus orientalis'),
        VegetationRow(height: '30', species: 'Abies nordmanniana'),
        VegetationRow(),
      ];
    final records = [a, _record('B')];
    expect(valuesOf(records, l10n.compareVegRows), ['2', null]);
    expect(valuesOf(records, l10n.compareMaxHeight), ['30', null]);
    expect(valuesOf(records, l10n.species), ['Fagus orientalis, Abies nordmanniana', null]);
  });

  test('horizons compare by their order, and tiers by their names', () {
    final a = _record('A')
      ..vegetation = [VegetationRow(tier: 'I'), VegetationRow(tier: ' i '), VegetationRow(tier: 'II')]
      ..soilHorizons = [
        SoilHorizonRow(horizon: 'A'),
        SoilHorizonRow(description: 'stony'),
        SoilHorizonRow(horizon: 'C'),
        SoilHorizonRow(),
      ];
    final records = [a, _record('B')];
    expect(valuesOf(records, l10n.compareTiers), ['I, II', null]);
    expect(valuesOf(records, l10n.compareHorizonOrder), ['A → ? → C', null]);
  });

  testWidgets('the differences switch hides equal lines', (tester) async {
    final a = _record('A')
      ..name = 'First'
      ..reliefType = 'Plateau';
    final b = _record('B')
      ..name = 'Second'
      ..reliefType = 'Valley';
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CompareScreen(records: [a, b]),
    ));

    expect(find.text('First'), findsOneWidget);
    expect(find.text('2026-07-01'), findsNWidgets(2));
    expect(find.text('Valley'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(find.text('2026-07-01'), findsNothing);
    expect(find.text('Valley'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
