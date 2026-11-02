import 'package:btk_field_app/data/repositories/data_repository.dart';
import 'package:btk_field_app/data/services/template_service.dart';
import 'package:btk_field_app/features/form/ui/btk_form_screen.dart';
import 'package:btk_field_app/features/records/domain/btk_provider.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/l10n/generated/app_localizations_en.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:btk_field_app/models/record_quality.dart';
import 'package:btk_field_app/models/record_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repository extends DataRepository {
  final List<BtkRecord> saved = [];
  bool fail = false;

  @override
  Future<List<BtkRecord>> getAll() async => [];
  @override
  Future<bool> upsert(BtkRecord record, {bool keepUpdatedAt = false}) async {
    if (fail) throw StateError('disk full');
    saved.add(BtkRecord.fromJson(record.toJson()));
    return false;
  }

  @override
  Future<void> delete(String id) async {}
}

BtkRecord _record({String id = 'A'}) => BtkRecord(id: id, date: DateTime(2026));

BtkRecord _finished() => _record()
  ..location = 'რაჭა'
  ..latitude = 42.5
  ..longitude = 43.1;

final _en = AppLocalizationsEn();

List<String> _messages(BtkRecord r) =>
    r.qualityNotes(now: DateTime(2026, 6)).map((n) => n.message(_en)).toList();

Future<void> _openForm(WidgetTester tester, BtkRecord record, _Repository repo) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [btkProvider.overrideWith((ref) => BtkNotifier(repo))],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          child: const Text('open'),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => BtkFormScreen(record: record))),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  final NavigatorState nav = tester.state(find.byType(Navigator).first);
  await nav.maybePop();
  await tester.pumpAndSettle();
}

void main() {
  group('unfinished status', () {
    test('needs a location and coordinates', () {
      expect(_record().isUnfinished, isTrue);
      expect((_record()..location = 'x').isUnfinished, isTrue);
      expect(_finished().isUnfinished, isFalse);
    });

    test('a section counts as filled once anything is typed in it', () {
      final r = _record();
      expect(r.isFilled(FormSection.vegetation), isFalse);
      expect(r.isFilled(FormSection.geomass), isFalse);
      r.vegetation.first.species = 'მუხა';
      r.experimentPlotSize = '10x10';
      expect(r.isFilled(FormSection.vegetation), isTrue);
      expect(r.isFilled(FormSection.geomass), isTrue);
      expect(r.isFilled(FormSection.soil), isFalse);
    });
  });

  group('data-quality notes', () {
    test('a clean record has none', () {
      expect(_messages(_finished()), isEmpty);
    });

    test('points at the missing basics, in the right section', () {
      final notes = _record().qualityNotes(now: DateTime(2026, 6));
      expect(notes.map((n) => n.section).toSet(), {FormSection.basic});
      expect(notes, hasLength(2));
    });

    test('flags impossible coordinates and a future date', () {
      final r = _finished()
        ..latitude = 95
        ..date = DateTime(2027);
      expect(_messages(r), [_en.qualityBadCoords, _en.qualityFutureDate]);
    });

    test('names the row and field of an odd value', () {
      final r = _finished()..geomasses.first.pedomassBulk = '12';
      expect(_messages(r).single,
          _en.qualityRow(1, _en.qualityOutOfRange(_en.gmPedBulk)));
    });

    test('dry mass above wet mass is flagged, equal is not', () {
      final r = _finished()
        ..geomasses.first.phytomassWet = '2'
        ..geomasses.first.phytomassDry = '3';
      expect(_messages(r).single, contains(_en.gmPhytDry));
      r.geomasses.first.phytomassDry = '2';
      expect(_messages(r), isEmpty);
    });

    test('a total is compared only when every part is known', () {
      final t = TreePhytomassRow(wetWood: '10', wetLeaves: '1', wetBranches: '2', wetTotal: '50');
      final r = _finished()..treePhytomass = [t];
      expect(_messages(r), isEmpty);

      t.wetRoots = '3';
      expect(_messages(r).single, contains('16.0'));

      t.wetTotal = '16,3';
      expect(_messages(r), isEmpty, reason: 'rounding differences are allowed');
    });

    test('values that are classes on the field sheet are left alone', () {
      final r = _finished()..vegetation.first.density = 'P';
      expect(_messages(r), isEmpty);
    });
  });

  group('filling from another record', () {
    BtkRecord source() => _finished()
      ..geologicalFormation = 'source formation'
      ..reliefType = 'source relief'
      ..vegetation = [VegetationRow(species: 'მუხა'), VegetationRow()]
      ..soilTypeName = 'ყომრალი'
      ..experimentPlotSize = '10x10';

    test('fills empty parts and counts them', () {
      final t = _record();
      final n = fillEmptyParts(t, source(), {FormSection.physGeo, FormSection.vegetation});
      expect(n, 3);
      expect(t.reliefType, 'source relief');
      expect(t.vegetation.single.species, 'მუხა', reason: 'blank rows are not copied');
    });

    test('never replaces what is already typed', () {
      final t = _record()
        ..reliefType = 'mine'
        ..vegetation.first.tier = 'IX';
      fillEmptyParts(t, source(), {FormSection.physGeo, FormSection.vegetation});
      expect(t.reliefType, 'mine');
      expect(t.geologicalFormation, 'source formation');
      expect(t.vegetation.single.tier, 'IX');
      expect(t.vegetation.single.species, '');
    });

    test('leaves sections that were not chosen', () {
      final t = _record();
      fillEmptyParts(t, source(), {FormSection.physGeo});
      expect(t.soilTypeName, '');
      expect(t.experimentPlotSize, '');
    });

    test('never copies identity, place or date', () {
      final t = _record(id: 'B');
      fillEmptyParts(t, source(), FormSection.values.toSet());
      expect(t.id, 'B');
      expect(t.location, '');
      expect(t.latitude, isNull);
      expect(t.date, DateTime(2026));
    });

    test('copied rows are independent of the source', () {
      final s = source();
      final t = _record();
      fillEmptyParts(t, s, {FormSection.vegetation});
      t.vegetation.first.species = 'changed';
      expect(s.vegetation.first.species, 'მუხა');
    });
  });

  group('templates', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    RecordTemplate template(String id) => RecordTemplate.fromRecord(
          id: id,
          name: 'name $id',
          from: _finished()
            ..soilTypeName = 'ყომრალი'
            ..reliefType = 'left out',
          sections: {FormSection.soil},
        );

    test('keep only the chosen sections, with no place', () {
      final c = template('T').content;
      expect(c.soilTypeName, 'ყომრალი');
      expect(c.reliefType, '');
      expect(c.location, '');
      expect(c.latitude, isNull);
    });

    test('are stored, listed and deleted', () async {
      await TemplateService.add(template('T1'));
      await TemplateService.add(template('T2'));
      var all = await TemplateService.load();
      expect(all.map((t) => t.name), ['name T1', 'name T2']);
      expect(all.first.content.soilTypeName, 'ყომრალი');

      await TemplateService.delete('T1');
      all = await TemplateService.load();
      expect(all.map((t) => t.id), ['T2']);
    });

    test('a damaged entry does not hide the others', () async {
      SharedPreferences.setMockInitialValues({
        'record_templates':
            '[{"id":"bad"},{"id":"ok","name":"n","content":{"id":"ok","date":"2026-01-01"}}]',
      });
      expect((await TemplateService.load()).map((t) => t.id), ['ok']);
    });

    test('unreadable storage reads as empty', () async {
      SharedPreferences.setMockInitialValues({'record_templates': 'not json'});
      expect(await TemplateService.load(), isEmpty);
    });
  });

  group('leaving the form', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> typeLocation(WidgetTester tester) async {
      await tester.enterText(
          find.widgetWithText(TextField, _en.location).first, 'რაჭა');
      await tester.pump();
    }

    testWidgets('saves pending edits with no question', (tester) async {
      final repo = _Repository();
      await _openForm(tester, _record(), repo);
      await typeLocation(tester);

      await _back(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(BtkFormScreen), findsNothing);
      expect(repo.saved.last.location, 'რაჭა');
    });

    testWidgets('stays when the save fails and the user chooses to', (tester) async {
      final repo = _Repository()..fail = true;
      await _openForm(tester, _record(), repo);
      await typeLocation(tester);

      await _back(tester);
      expect(find.text(_en.exitSaveFailed), findsOneWidget);

      await tester.tap(find.text(_en.stay));
      await tester.pumpAndSettle();
      expect(find.byType(BtkFormScreen), findsOneWidget);

      repo.fail = false;
      await _back(tester);
      expect(repo.saved.last.location, 'რაჭა');
    });

    testWidgets('saves when the app goes to the background', (tester) async {
      final repo = _Repository();
      await _openForm(tester, _record(), repo);
      await typeLocation(tester);
      expect(repo.saved, isEmpty, reason: 'autosave is still waiting');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(repo.saved.single.location, 'რაჭა');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      expect(repo.saved, hasLength(1), reason: 'the waiting save was replaced');
    });

    testWidgets('undo restores the record as it was opened', (tester) async {
      final repo = _Repository();
      await _openForm(tester, _record()..location = 'original', repo);
      await tester.enterText(
          find.widgetWithText(TextField, _en.location).first, 'changed');
      await tester.pump(const Duration(seconds: 1));
      expect(repo.saved.last.location, 'changed');

      await tester.tap(find.byTooltip(_en.recordMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en.revertChanges));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en.revertAction));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'original'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(repo.saved.last.location, 'original');
    });
  });
}
