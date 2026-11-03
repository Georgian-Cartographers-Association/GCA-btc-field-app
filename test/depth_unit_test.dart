import 'package:btk_field_app/features/form/ui/sections/geomass_section.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:btk_field_app/models/record_quality.dart';
import 'package:btk_field_app/models/record_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BtkRecord _record(String unit, String depth) =>
    BtkRecord(id: 'A', date: DateTime(2026), depthUnit: unit)
      ..geomasses = [GeomassRow(depth: depth)];

Iterable<QualityNote> _geomassNotes(BtkRecord r) =>
    r.qualityNotes().where((n) => n.section == FormSection.geomass);

void main() {
  test('metres become centimetres for comparison', () {
    final r = _record(depthUnitM, '0,14-0,42');
    final range = r.depthRangeCm(r.geomasses.first)!;
    expect(range.from, closeTo(14, 1e-9));
    expect(range.to, closeTo(42, 1e-9));
  });

  test('centimetres stay as typed', () {
    final r = _record(depthUnitCm, '10-20');
    expect(r.depthRangeCm(r.geomasses.first)!.to, 20);
  });

  test('no unit gives no depth, so nothing is guessed', () {
    final r = _record('', '10-20');
    expect(r.depthRangeCm(r.geomasses.first), isNull);
  });

  test('old records stay readable and their JSON gains nothing', () {
    final json = _record('', '10-20').toJson();
    expect(json.containsKey('depthUnit'), isFalse);
    expect(BtkRecord.fromJson(json).depthUnit, '');
  });

  test('the chosen unit round-trips', () {
    final json = _record(depthUnitM, '1').toJson();
    expect(BtkRecord.fromJson(json).depthUnit, depthUnitM);
  });

  test('a depth without a unit gets a note, which goes once chosen', () {
    expect(_geomassNotes(_record('', '10')), hasLength(1));
    expect(_geomassNotes(_record(depthUnitCm, '10')), isEmpty);
    expect(_geomassNotes(_record('', '')), isEmpty);
  });

  test('reuse brings the unit only along with the depths', () {
    final source = _record(depthUnitM, '1');

    final empty = BtkRecord(id: 'B', date: DateTime(2026));
    fillEmptyParts(empty, source, {FormSection.geomass});
    expect(empty.depthUnit, depthUnitM);

    final own = _record('', '50');
    fillEmptyParts(own, source, {FormSection.geomass});
    expect(own.geomasses.first.depth, '50');
    expect(own.depthUnit, '');
  });

  testWidgets('picking a unit stores it and shows it on the column', (tester) async {
    final record = _record('', '10');
    var changes = 0;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GeomassSection(record: record, onChanged: (_) => changes++),
      ),
    ));
    expect(find.text('Depth unit not chosen'), findsOneWidget);

    await tester.tap(find.text('m'));
    await tester.pump();

    expect(record.depthUnit, depthUnitM);
    expect(changes, 1);
    expect(find.text('Depth\nm'), findsOneWidget);
    expect(find.text('Depth unit'), findsOneWidget);
  });

  testWidgets('the hydromass explanation opens', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GeomassSection(record: _record('', ''), onChanged: (_) {}),
      ),
    ));

    await tester.tap(find.text('Hydromass explained'));
    await tester.pumpAndSettle();

    expect(find.textContaining('including its water'), findsOneWidget);
    expect(find.textContaining('after drying'), findsOneWidget);
  });
}
