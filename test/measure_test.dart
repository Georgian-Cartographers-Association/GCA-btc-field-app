import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/features/form/ui/sections/vegetation_section.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:btk_field_app/models/measure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BtkRecord _record() => BtkRecord(id: 'A', date: DateTime(2026));

Future<void> _pump(WidgetTester tester, Widget section) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ka'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: section),
      ),
    );

void main() {
  group('reading values from the field sheet', () {
    test('accepts a decimal comma and a decimal point', () {
      expect(Measures.vegHeight.value('0,5'), 0.5);
      expect(Measures.vegHeight.value('0.5'), 0.5);
      expect(Measures.vegHeight.value(' 18 '), 18);
    });

    test('accepts the field\'s own unit and refuses another', () {
      expect(Measures.vegHeight.value('18 მ'), 18);
      expect(Measures.vegHeight.value('18m'), 18);
      expect(Measures.vegHeight.value('50 სმ'), isNull);
      expect(Measures.vegHeight.value('50 cm'), isNull);
    });

    test('reads ranges with any dash', () {
      final r = Measures.vertHeight.range('16-32 მ')!;
      expect([r.from, r.to], [16, 32]);
      final dash = Measures.depth.range('0,14–0,42')!;
      expect([dash.from, dash.to], [0.14, 0.42]);
      expect(Measures.depth.range('10')!.to, 10);
      expect(Measures.depth.range('ზედა'), isNull);
    });

    test('reads a plot size as an area', () {
      expect(Measures.plotSize.area('50X100 მ2'), 5000);
      expect(Measures.plotSize.area('10x10'), 100);
      expect(Measures.plotSize.area('10 ხ 10'), 100);
      expect(Measures.plotSize.area('2500'), 2500);
    });

    test('rejects text that only looks numeric', () {
      for (final bad in ['1,2,3', '1.2.3', '-5', 'P', '1e5', ',']) {
        expect(Measures.plain.value(bad), isNull, reason: bad);
      }
    });
  });

  group('warnings', () {
    test('an empty field is fine', () {
      expect(Measures.soilBulkDensity.check(''), isNull);
      expect(Measures.depth.check('  '), isNull);
    });

    test('values from the methodology tables pass', () {
      for (final v in ['0,3', '1.02', '1,7']) {
        expect(Measures.soilBulkDensity.check(v), isNull, reason: v);
      }
      for (final v in ['1,5', '2.7', '2,8']) {
        expect(Measures.rockDensity.check(v), isNull, reason: v);
      }
      expect(Measures.vegHeight.check('0,5'), isNull);
      expect(Measures.vertHeight.check('16-32 მ'), isNull);
      expect(Measures.plotSize.check('50X100 მ2'), isNull);
    });

    test('a misplaced decimal point is out of range', () {
      expect(Measures.soilBulkDensity.check('12'), MeasureIssue.outOfRange);
      expect(Measures.vegHeight.check('180'), MeasureIssue.outOfRange);
      expect(Measures.depth.check('20-10'), MeasureIssue.outOfRange);
      expect(Measures.plotSize.check('0x10'), MeasureIssue.outOfRange);
    });

    test('text is unreadable', () {
      expect(Measures.geomass.check('ბევრი'), MeasureIssue.unreadable);
      expect(Measures.depth.check('ბევრი'), MeasureIssue.unreadable);
      expect(Measures.plotSize.check('ბევრი'), MeasureIssue.unreadable);
    });
  });

  group('records keep their text', () {
    test('old values survive reading and saving unchanged', () {
      final json = {
        'id': 'OLD1',
        'date': '2020-07-25T00:00:00.000',
        'experimentPlotSize': '50X100 მ2',
        'vertStructHeight': 'სიმაღლითი გრადაცია 16-32 მ',
        'vegetation': [
          {'tier': 'IX', 'height': '0,5', 'density': 'P', 'phenophase': '4', 'species': 'მუხა'},
        ],
        'geomasses': [
          {'section': 'A', 'depth': '0,00-0,14', 'pedomassBulk': 'დაახლ. 1,2'},
        ],
      };

      final saved = BtkRecord.fromJson(json).toJson();

      expect(saved['experimentPlotSize'], '50X100 მ2');
      expect(saved['vertStructHeight'], 'სიმაღლითი გრადაცია 16-32 მ');
      final veg = (saved['vegetation'] as List).single as Map;
      expect(veg['height'], '0,5');
      expect(veg['density'], 'P');
      final geo = (saved['geomasses'] as List).single as Map;
      expect(geo['depth'], '0,00-0,14');
      expect(geo['pedomassBulk'], 'დაახლ. 1,2');
    });

    test('saved JSON has no new fields, so older versions read it the same', () {
      final keys = BtkRecord.fromJson({'id': 'A', 'date': '2026-01-01'}).toJson().keys;
      expect(keys, isNot(contains('schemaVersion')));
      expect(keys.where((k) => k.endsWith('Value')), isEmpty);
    });

    test('numbers stored by an edited file load as text and read as numbers', () {
      final r = BtkRecord.fromJson({
        'id': 'A',
        'date': '2026-01-01',
        'vegetation': [
          {'height': 18},
        ],
      });
      expect(r.vegetation.single.height, '18');
      expect(r.vegetation.single.heightValue, 18);
    });

    test('rows expose numbers', () {
      final g = GeomassRow(depth: '10-20', pedomassBulk: '1,25', phytomassDry: 'x');
      expect(g.depthRange!.to, 20);
      expect(g.pedomassBulkValue, 1.25);
      expect(g.phytomassDryValue, isNull);
      expect(g.lithomassQtyValue, isNull);

      final t = TreePhytomassRow(bulkDensity: '0,7', dryTotal: '120');
      expect(t.bulkDensityValue, 0.7);
      expect(t.dryTotalValue, 120);

      final r = _record()
        ..experimentPlotSize = '50X100'
        ..vertStructHeight = '16-32 მ';
      expect(r.plotArea, 5000);
      expect(r.vertHeightRange!.from, 16);
    });
  });

  group('form', () {
    testWidgets('an odd value is still kept', (tester) async {
      final record = _record();
      await _pump(tester, VegetationSection(record: record, onChanged: (_) {}));

      await tester.enterText(find.byType(TextField).at(1), 'მაღალი');
      await tester.pump();

      expect(record.vegetation.single.height, 'მაღალი');
      expect(find.byType(Tooltip), findsWidgets);
    });
  });
}
