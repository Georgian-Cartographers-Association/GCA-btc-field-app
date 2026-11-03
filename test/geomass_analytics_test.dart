import 'package:btk_field_app/features/stats/domain/geomass_analytics.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BtkRecord _record(String id, {String unit = depthUnitCm}) =>
    BtkRecord(id: id, date: DateTime(2026, 7, 1))..depthUnit = unit;

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  ComponentSummary component(GeomassAnalytics a, String label) =>
      a.components.firstWhere((c) => c.component.label(l10n) == label);

  test('records with only blank rows count as having no data', () {
    final a = _record('A')
      ..geomasses = [GeomassRow()]
      ..treePhytomass = [TreePhytomassRow()];
    final result = GeomassAnalytics.of([a]);
    expect(result.hasData, isFalse);
    expect(result.components, isEmpty);
    expect(result.layers, isEmpty);
  });

  test('totals are per record, and the range runs across records', () {
    final a = _record('A')
      ..geomasses = [GeomassRow(pedomassQty: '10'), GeomassRow(pedomassQty: '5,5')];
    final b = _record('B')..geomasses = [GeomassRow(pedomassQty: '40 ტ/ჰა')];
    final pedomass = component(GeomassAnalytics.of([a, b]), l10n.comparePedomass);
    expect(pedomass.records, 2);
    expect(pedomass.totals.text, '15.5–40');
  });

  test('a record with an unreadable value stays out of the range and is counted', () {
    final a = _record('A')
      ..geomasses = [GeomassRow(pedomassQty: '10'), GeomassRow(pedomassQty: 'ბევრი')];
    final b = _record('B')..geomasses = [GeomassRow(pedomassQty: '40')];
    final pedomass = component(GeomassAnalytics.of([a, b]), l10n.comparePedomass);
    expect(pedomass.records, 2);
    expect(pedomass.totals.text, '40, ?×1');
  });

  test('tree phytomass alone counts as geomass data', () {
    final a = _record('A')..treePhytomass = [TreePhytomassRow(wetTotal: '120')];
    final result = GeomassAnalytics.of([a]);
    expect(result.recordsWithData, 1);
    expect(component(result, l10n.compareTreeWet).totals.text, '120');
    expect(result.layers, isEmpty);
  });

  test('metres and centimetres meet in one layer, sorted by depth', () {
    final metres = _record('A', unit: depthUnitM)
      ..geomasses = [
        GeomassRow(depth: '0,2-0,5', pedomassQty: '30'),
        GeomassRow(depth: '0-0,2', pedomassQty: '20'),
      ];
    final cm = _record('B')..geomasses = [GeomassRow(depth: '0-20', pedomassQty: '25')];
    final layers = GeomassAnalytics.of([metres, cm]).layers;
    expect(layers.map((l) => l.text), ['0–20', '20–50']);
    expect(layers.first.records, 2);
    expect(layers.first.values.first.text, '20–25');
  });

  test('close but different ranges stay apart', () {
    final a = _record('A')
      ..geomasses = [GeomassRow(depth: '0-20', pedomassQty: '1'), GeomassRow(depth: '0-25', pedomassQty: '1')];
    expect(GeomassAnalytics.of([a]).layers.length, 2);
  });

  test('blank, unreadable and unit-less depths share the unknown layer, last', () {
    final noUnit = _record('A', unit: '')..geomasses = [GeomassRow(depth: '50', pedomassQty: '5')];
    final blank = _record('B')..geomasses = [GeomassRow(pedomassQty: '7')];
    final known = _record('C')
      ..geomasses = [GeomassRow(depth: '0-10', pedomassQty: '9'), GeomassRow(depth: 'ღრმა', pedomassQty: '8')];
    final layers = GeomassAnalytics.of([noUnit, blank, known]).layers;
    expect(layers.map((l) => l.isKnown), [true, false]);
    expect(layers.last.records, 3);
    expect(layers.last.values.first.text, '5–8');
  });

  test('a layer counts a record once, however many rows it has there', () {
    final a = _record('A')
      ..geomasses = [
        GeomassRow(section: '1', depth: '0-20', lithomassQty: '3'),
        GeomassRow(section: '2', depth: '0-20', lithomassQty: 'x'),
      ];
    final layer = GeomassAnalytics.of([a]).layers.single;
    expect(layer.records, 1);
    expect(layer.values[1].text, '3, ?×1');
    expect(layer.values[0].text, isNull);
  });
}
