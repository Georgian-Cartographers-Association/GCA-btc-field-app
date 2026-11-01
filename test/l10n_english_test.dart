import 'package:btk_field_app/data/repositories/data_repository.dart';
import 'package:btk_field_app/features/auth/domain/firebase_auth_provider.dart';
import 'package:btk_field_app/features/auth/ui/auth_screen.dart';
import 'package:btk_field_app/features/form/ui/btk_form_screen.dart';
import 'package:btk_field_app/features/layers/ui/layers_screen.dart';
import 'package:btk_field_app/features/map/ui/widgets/layer_control_panel.dart';
import 'package:btk_field_app/features/map/ui/widgets/map_search_sheet.dart';
import 'package:btk_field_app/features/map/ui/widgets/measurement_panel.dart';
import 'package:btk_field_app/features/records/domain/btk_provider.dart';
import 'package:btk_field_app/features/records/ui/records_screen.dart';
import 'package:btk_field_app/features/settings/ui/settings_screen.dart';
import 'package:btk_field_app/features/stats/ui/stats_screen.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:btk_field_app/utils/measurement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryRepository extends DataRepository {
  @override
  Future<List<BtkRecord>> getAll() async => [
        BtkRecord(id: 'TEST', date: DateTime(2026, 1, 15), location: 'Tbilisi'),
      ];
  @override
  Future<bool> upsert(BtkRecord record) async => false;
  @override
  Future<void> delete(String id) async {}
}

final _georgian = RegExp(r'[Ⴀ-ჿ]');

/// Institution names shown in Settings → About stay in Georgian.
const _allowed = {
  'ალ. ასლანიკაშვილის სახ.\nსაქართველოს კარტოგრაფთა ასოციაცია',
  'ი. ჯავახიშვილის სახ. თბილისის სახ. უნ-ტი',
  'ქართული',
};

/// Every string the current tree shows: text, tooltips, labels and hints.
List<String> _visibleStrings(WidgetTester tester) {
  final out = <String>[];
  void add(String? s) {
    if (s != null && s.isNotEmpty) out.add(s);
  }

  for (final e in tester.allElements) {
    final w = e.widget;
    if (w is Text) {
      add(w.data ?? w.textSpan?.toPlainText());
    } else if (w is RichText) {
      add(w.text.toPlainText());
    } else if (w is Tooltip) {
      add(w.message);
    } else if (w is InputDecorator) {
      final d = w.decoration;
      add(d.labelText);
      add(d.hintText);
      add(d.helperText);
      add(d.errorText);
    }
  }
  return out;
}

void _expectNoGeorgian(WidgetTester tester, String where) {
  final bad = _visibleStrings(tester)
      .where((s) => _georgian.hasMatch(s) && !_allowed.contains(s))
      .toSet();
  expect(bad, isEmpty, reason: 'Georgian text on $where');
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => Stream.value(null)),
      btkProvider.overrideWith((ref) => BtkNotifier(_MemoryRepository())),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('ka'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'locale': 'en'}));

  testWidgets('Settings', (tester) async {
    await _pump(tester, const SettingsScreen());
    _expectNoGeorgian(tester, 'Settings');
  });

  testWidgets('Records', (tester) async {
    await _pump(tester, const RecordsScreen());
    _expectNoGeorgian(tester, 'Records');
  });

  testWidgets('Auth', (tester) async {
    await _pump(tester, const AuthScreen());
    _expectNoGeorgian(tester, 'Auth');
  });

  testWidgets('Stats', (tester) async {
    await _pump(tester, const StatsScreen());
    _expectNoGeorgian(tester, 'Stats');
  });

  testWidgets('Layers, both tabs', (tester) async {
    await _pump(tester, const LayersScreen());
    _expectNoGeorgian(tester, 'Layers/rasters');
    await tester.tap(find.text('Web services'));
    await tester.pumpAndSettle();
    _expectNoGeorgian(tester, 'Layers/web services');
  });

  testWidgets('Form, every tab', (tester) async {
    final record = BtkRecord(id: 'TEST', date: DateTime(2026, 1, 15));
    await _pump(tester, BtkFormScreen(record: record));
    final tabs = find.descendant(
        of: find.byType(TabBar), matching: find.byType(Tab));
    final count = tabs.evaluate().length;
    expect(count, greaterThanOrEqualTo(6));
    for (var i = 0; i < count; i++) {
      await tester.tap(tabs.at(i));
      await tester.pumpAndSettle();
      _expectNoGeorgian(tester, 'Form tab $i');
    }
  });

  testWidgets('Map panels', (tester) async {
    await _pump(
        tester,
        Scaffold(
          body: ListView(children: [
            const LayerControlPanel(),
            for (final mode in MeasureMode.values)
              MeasurementPanel(
                mode: mode,
                points: const [],
                onModeChanged: (_) {},
                onUndo: () {},
                onClear: () {},
                onClose: () {},
              ),
          ]),
        ));
    _expectNoGeorgian(tester, 'Map panels');
  });

  testWidgets('Map search sheet', (tester) async {
    await _pump(
        tester,
        Scaffold(
          body: MapSearchSheet(localIndex: const [], onSelect: (_) {}),
        ));
    _expectNoGeorgian(tester, 'Map search');
  });
}
