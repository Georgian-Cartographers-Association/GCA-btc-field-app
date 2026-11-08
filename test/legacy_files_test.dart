import 'dart:convert';
import 'dart:io';

import 'package:btk_field_app/data/services/export_service.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// test/fixtures/legacy_v1.btk was written by the app's first .btk export
/// (commit 4bd8548, August 2026), with values like those on the field sheet.
/// Never regenerate it with the current code: it stands for files people
/// already have.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = lookupAppLocalizations(const Locale('ka'));
  late List<BtkRecord> records;

  setUpAll(() {
    final text = File('test/fixtures/legacy_v1.btk').readAsStringSync();
    records = ExportService.decodeBtk(text, l10n);
  });

  test('every record of a first-version .btk file loads', () {
    expect(records.map((r) => r.id), ['A1B2C3D4', 'E5F6A7B8']);
  });

  test('the old fields keep their values', () {
    final r = records.first;
    expect(r.name, 'რაჭა 101');
    expect(r.date, DateTime.utc(2026, 7, 14, 10, 30));
    expect(r.latitude, 42.5371);
    expect(r.longitude, 43.0915);
    expect(r.altitude, 1640);
    expect(r.aspect, 135);
    expect(r.reliefType, 'ეროზიულ-დენუდაციური');
    expect(r.experimentPlotSize, '50X100');
    expect(r.vertStructIndex, '5Fk5w (71)');
    expect(r.vertStructHeight, '16-32 მ');

    expect(r.vegetation, hasLength(2));
    expect(r.vegetation.first.species, 'Fagus orientalis');
    expect(r.vegetation.last.density, 'P');
    expect(r.soilHorizons.map((h) => h.horizon), ['A0 0-3', 'A1 3-15']);
    expect(r.geomasses.single.pedomassBulk, '1.10');
    expect(r.geomasses.single.phytomassDry, '1.2');
    expect(r.treePhytomass.single.dryTotal, '261.5');
  });

  test('a record with nothing filled in loads', () {
    final r = records.last;
    expect(r.name, isEmpty);
    expect(r.latitude, isNull);
  });

  test('old records survive a save and reload in the current format', () {
    final again = ExportService.decodeBtk(
        jsonEncode({
          'btk_export_version': 1,
          'records': records.map((r) => r.toJson()).toList(),
        }),
        l10n);
    expect(again.map((r) => r.toJson()), records.map((r) => r.toJson()));
  });

  test('old records still export to the other formats', () async {
    expect(ExportService.buildCsv(records), contains('"A1B2C3D4"'));
    expect(ExportService.buildKml(records), contains('რაჭა 101'));
    expect(ExportService.buildGeoJson(records), contains('A1B2C3D4'));
    final pdf = await ExportService.buildPdf(records);
    expect(ascii.decode(pdf.sublist(0, 5)), '%PDF-');
  });

  test('a file that is not a .btk export is refused', () {
    expect(() => ExportService.decodeBtk('{"records": []}', l10n),
        throwsException);
  });
}
