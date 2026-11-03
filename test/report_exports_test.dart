import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:btk_field_app/data/services/export_service.dart';
import 'package:btk_field_app/data/services/records_workbook.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BtkRecord _full() => BtkRecord(id: 'A', date: DateTime(2026, 7, 1))
  ..name = 'Omalo <1> & "2"'
  ..group = 'Tusheti'
  ..altitude = 1880
  ..aspect = 135
  ..latitude = 42.3
  ..longitude = 45.6
  ..soilProfileDesc = 'profile text'
  ..vertStructDesc = 'vertical text'
  ..experimentPlotSize = '50X100'
  ..depthUnit = depthUnitM
  ..vegetation = [VegetationRow(tier: 'I', height: '30', species: 'Fagus'), VegetationRow()]
  ..soilHorizons = [SoilHorizonRow(horizon: 'Ah', description: 'dark'), SoilHorizonRow()]
  ..geomasses = [
    GeomassRow(depth: '0-0,2', pedomassQty: '10,5', lithomassQty: 'many'),
    GeomassRow(),
  ]
  ..treePhytomass = [TreePhytomassRow(species: 'Abies', wetTotal: '210')];

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('CSV', () {
    test('old columns keep their place and the new ones come last', () {
      final lines = ExportService.buildCsv([_full()]).trim().split('\n');
      final header = lines.first.split(',');
      expect(header.first, 'ID');
      expect(header[16], 'ვ.ს.სიმ.');
      expect(header[17], 'სახელი');
      expect(lines[1], contains('"Tusheti"'));
      expect(lines[1], contains('"profile text"'));
    });

    test('a formula in a name is neutralised', () {
      final r = BtkRecord(id: 'B', date: DateTime(2026))..name = '=SUM(A1)';
      expect(ExportService.buildCsv([r]), contains('"\'=SUM(A1)"'));
    });
  });

  group('GeoJSON', () {
    test('carries the fields and filled rows of every table', () {
      final json = jsonDecode(ExportService.buildGeoJson([_full()]));
      final props = json['features'][0]['properties'];
      expect(props['id'], 'A');
      expect(props['altitude'], 1880);
      expect(props['vegetation'], hasLength(1));
      expect(props['soil_horizons'][0]['horizon'], 'Ah');
      expect(props['geomasses'][0]['pedomassQty'], '10,5');
      expect(props['tree_phytomass'][0]['species'], 'Abies');
    });

    test('a record without coordinates or tables still exports', () {
      final json = jsonDecode(
          ExportService.buildGeoJson([BtkRecord(id: 'B', date: DateTime(2026))]));
      expect(json['features'][0]['geometry'], isNull);
      expect(json['features'][0]['properties']['vegetation'], isEmpty);
    });
  });

  group('KML', () {
    test('describes the tables, and text cannot close its CDATA early', () {
      final r = _full()..location = 'a]]>b';
      final kml = ExportService.buildKml([r]);
      expect(kml, contains('Fagus'));
      expect(kml, contains('Abies'));
      expect(kml, contains('vertical text'));
      expect(kml, isNot(contains('a]]>b')));
      expect(kml, contains('a]]]]><![CDATA[>b'));
    });
  });

  group('Excel workbook', () {
    String part(Archive zip, String name) =>
        utf8.decode(zip.findFile(name)!.content as List<int>);

    late Archive zip;

    setUp(() {
      zip = ZipDecoder().decodeBytes(buildRecordsWorkbook([_full()], l10n));
    });

    test('holds one sheet for the records and one per table', () {
      final workbook = part(zip, 'xl/workbook.xml');
      expect('<sheet '.allMatches(workbook), hasLength(5));
      expect(zip.findFile('xl/worksheets/sheet5.xml'), isNotNull);
    });

    test('text is escaped, and rows that are blank are left out', () {
      final records = part(zip, 'xl/worksheets/sheet1.xml');
      expect(records, contains('Omalo &lt;1&gt; &amp; &quot;2&quot;'));
      final vegetation = part(zip, 'xl/worksheets/sheet2.xml');
      expect('<row '.allMatches(vegetation), hasLength(2));
    });

    test('readable values are numbers, others stay as typed, depth is in cm', () {
      final geomass = part(zip, 'xl/worksheets/sheet4.xml');
      expect(geomass, contains('<v>10.5</v>'));
      expect(geomass, contains('>many<'));
      expect(geomass, contains('>0-0,2<'));
      expect(geomass, contains('<v>20.0</v>'));
    });

    test('a long or repeated sheet name stays legal', () {
      final names = RegExp(r'<sheet name="([^"]*)"')
          .allMatches(part(zip, 'xl/workbook.xml'))
          .map((m) => m[1]!);
      expect(names.every((n) => n.length <= 31), isTrue);
      expect(names.toSet().length, 5);
    });
  });

  test('a record saved by an old version goes through every format', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final old = BtkRecord.fromJson({'id': 'old', 'date': '2020-05-01T00:00:00.000'});
    expect(ExportService.buildCsv([old]), contains('"old"'));
    expect(jsonDecode(ExportService.buildGeoJson([old]))['features'], hasLength(1));
    expect(ExportService.buildKml([old]), contains('<kml'));
    expect(buildRecordsWorkbook([old], l10n), isNotEmpty);
    expect(await ExportService.buildPdf([old]), isNotEmpty);
    final copy = BtkRecord.fromJson(jsonDecode(jsonEncode(old.toJson())));
    expect(copy.depthUnit, isEmpty);
  });

  test('a full record makes a PDF', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final pdf = await ExportService.buildPdf([_full()]);
    expect(latin1.decode(pdf.sublist(0, 4)), '%PDF');
  });
}
