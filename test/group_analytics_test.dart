import 'package:btk_field_app/features/stats/domain/geomass_analytics.dart';
import 'package:btk_field_app/features/stats/domain/group_analytics.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BtkRecord _record(String id, {double? altitude, DateTime? date, String location = ''}) =>
    BtkRecord(id: id, date: date ?? DateTime(2026, 7, 1))
      ..altitude = altitude
      ..location = location;

void main() {
  test('a value on a limit goes to the upper band, and empty bands are not listed', () {
    final bands = altitudeBands([
      _record('A', altitude: 499.9),
      _record('B', altitude: 500),
      _record('C', altitude: 2100),
    ], 500);
    expect(bands.map((b) => b.label), ['0–500', '500–1000', '2000–2500']);
    expect(bands.map((b) => b.records), [1, 1, 1]);
  });

  test('the step changes the bands', () {
    final records = [_record('A', altitude: 120), _record('B', altitude: 180)];
    expect(altitudeBands(records, 100).map((b) => b.label), ['100–200']);
    expect(altitudeBands(records, 250).map((b) => b.label), ['0–250']);
  });

  test('a height below sea level gets its own band', () {
    expect(altitudeBands([_record('A', altitude: -20)], 100).single.label, '-100–0');
    expect(altitudeBands([_record('A', altitude: -100)], 100).single.label, '-100–0');
  });

  test('records with no altitude stay visible, last', () {
    final bands = altitudeBands([_record('A'), _record('B', altitude: 700)], 500);
    expect(bands.map((b) => b.label), ['500–1000', null]);
  });

  test('a group counts distinct species and spans per-record totals', () {
    final a = _record('A', altitude: 100)
      ..vegetation = [VegetationRow(species: 'Fagus, Abies')]
      ..geomasses = [GeomassRow(pedomassQty: '10'), GeomassRow(pedomassQty: '5')];
    final b = _record('B', altitude: 200)
      ..vegetation = [VegetationRow(species: 'fagus')]
      ..geomasses = [GeomassRow(pedomassQty: '40')];
    final band = altitudeBands([a, b], 500).single;
    expect(band.species, 2);
    expect(band.masses.first.text, '15–40');
  });

  test('only columns holding data are used', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final a = _record('A', altitude: 100)..geomasses = [GeomassRow(lithomassQty: 'x')];
    final used = usedMassColumns(altitudeBands([a], 500));
    expect(used.map((i) => geomassComponents[i].label(l10n)), [l10n.compareLithomass]);
  });

  test('years run from earliest to latest', () {
    final groups = yearGroups([
      _record('A', date: DateTime(2026, 1, 1)),
      _record('B', date: DateTime(2024, 12, 31)),
      _record('C', date: DateTime(2026, 8, 1)),
    ]);
    expect(groups.map((g) => g.label), ['2024', '2026']);
    expect(groups.map((g) => g.records), [1, 2]);
  });

  test('a place repeats only on different days, oldest first', () {
    final places = repeatedPlaces([
      _record('A', date: DateTime(2026, 7, 1), location: 'ომალო'),
      _record('B', date: DateTime(2024, 7, 1), location: ' ომალო '),
      _record('C', date: DateTime(2026, 7, 1, 9), location: 'დართლო'),
      _record('D', date: DateTime(2026, 7, 1, 15), location: 'დართლო'),
      _record('E', date: DateTime(2025, 7, 1)),
      _record('F', date: DateTime(2026, 7, 1)),
    ]);
    expect(places.single.place, 'ომალო');
    expect(places.single.records.map((r) => r.id), ['B', 'A']);
    expect(shortDate(places.single.first), '2024-07-01');
  });
}
