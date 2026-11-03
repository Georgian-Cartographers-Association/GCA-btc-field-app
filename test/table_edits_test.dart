import 'package:btk_field_app/features/form/ui/sections/geomass_section.dart';
import 'package:btk_field_app/features/form/ui/sections/soil_section.dart';
import 'package:btk_field_app/features/form/ui/sections/vegetation_section.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BtkRecord _record() => BtkRecord(id: 'A', date: DateTime(2026));

Future<void> _pump(WidgetTester tester, Widget section) => tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ka'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: section),
        ),
      ),
    );

// Without the report, an edit gets no autosave or exit warning and is lost.
void main() {
  testWidgets('vegetation', (tester) async {
    final record = _record();
    var calls = 0;
    await _pump(tester, VegetationSection(record: record, onChanged: (_) => calls++));

    await tester.enterText(find.byType(TextField).at(1), '18');

    expect(calls, 1);
    expect(record.vegetation.single.height, '18');
  });

  testWidgets('soil horizons', (tester) async {
    final record = _record();
    var calls = 0;
    await _pump(tester, SoilSection(record: record, onChanged: (_) => calls++));

    await tester.enterText(find.byType(TextField).at(2), 'A');

    expect(calls, 1);
    expect(record.soilHorizons.single.horizon, 'A');
  });

  testWidgets('geomass and tree phytomass', (tester) async {
    final record = _record();
    var calls = 0;
    await _pump(tester, GeomassSection(record: record, onChanged: (_) => calls++));

    await tester.enterText(find.byType(TextField).at(2), '1,2');
    expect(calls, 1);
    expect(record.geomasses.single.pedomassBulk, '1,2');

    await tester.enterText(find.byType(TextField).last, '12');
    expect(calls, 2);
    expect(record.treePhytomass.single.dryTotal, '12');
  });
}
