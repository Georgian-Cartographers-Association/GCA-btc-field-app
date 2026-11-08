import 'dart:convert';

import 'package:btk_field_app/data/services/export_service.dart';
import 'package:btk_field_app/features/form/ui/widgets/english_field.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BtkRecord _record(String language) => BtkRecord(
      id: 'A',
      date: DateTime(2026, 7, 1),
      location: 'ომალო',
      fillLanguage: language,
      english: {'location': 'Omalo'},
      vegetation: [
        VegetationRow(tier: 'I', phenophase: 'ყვავილობა', english: {'phenophase': 'flowering'}),
      ],
      soilHorizons: [
        SoilHorizonRow(horizon: 'A', description: 'მუქი', english: {'description': 'dark'}),
      ],
    );

BtkRecord _roundTrip(BtkRecord r) => BtkRecord.fromJson(jsonDecode(jsonEncode(r.toJson())));

void main() {
  test('language and English text survive storage', () {
    final copy = _roundTrip(_record(fillBoth));
    expect(copy.fillLanguage, fillBoth);
    expect(copy.isBilingual, isTrue);
    expect(copy.english, {'location': 'Omalo'});
    expect(copy.vegetation.single.english, {'phenophase': 'flowering'});
    expect(copy.soilHorizons.single.english, {'description': 'dark'});
  });

  test('an old record is Georgian, and gains no new keys', () {
    final old = BtkRecord(id: 'A', date: DateTime(2026));
    final json = old.toJson();
    expect(json.containsKey('fillLanguage'), isFalse);
    expect(json.containsKey('en'), isFalse);
    expect(VegetationRow().toJson().containsKey('en'), isFalse);
    final copy = BtkRecord.fromJson(json);
    expect(copy.fillLang, fillKa);
    expect(copy.isBilingual, isFalse);
  });

  test('an unknown language or bad English reads as an old record', () {
    final json = _record(fillBoth).toJson()
      ..['fillLanguage'] = 'xx'
      ..['en'] = 'junk';
    final copy = BtkRecord.fromJson(json);
    expect(copy.fillLanguage, isEmpty);
    expect(copy.english, isEmpty);
  });

  test('switching away from both keeps the English text', () {
    final r = _record(fillBoth)..fillLanguage = fillKa;
    expect(_roundTrip(r).english, {'location': 'Omalo'});
  });

  test('a PDF builds in each language', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final language in [fillKa, fillEn, fillBoth, '']) {
      final pdf = await ExportService.buildPdf([_record(language)]);
      expect(latin1.decode(pdf.sublist(0, 4)), '%PDF', reason: language);
    }
  });

  testWidgets('clearing the English field removes its entry', (tester) async {
    final values = {'location': 'Omalo'};
    var changes = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EnglishField(
          values: values,
          fieldKey: 'location',
          label: 'Location',
          onChanged: () => changes++,
        ),
      ),
    ));
    expect(find.text('Omalo'), findsOneWidget);
    expect(find.text('Location · EN'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Omalo village');
    expect(values['location'], 'Omalo village');
    await tester.enterText(find.byType(TextField), ' ');
    expect(values.containsKey('location'), isFalse);
    expect(changes, 2);
  });
}
