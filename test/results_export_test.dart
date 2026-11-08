import 'package:btk_field_app/features/records/domain/record_filter.dart';
import 'package:btk_field_app/features/stats/domain/results_export.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  String csv(List<BtkRecord> records,
          {int? total, RecordFilter filter = const RecordFilter(), int step = 500}) =>
      buildResultsCsv(
        records: records,
        totalRecords: total ?? records.length,
        filter: filter,
        bandStep: step,
        l10n: l10n,
        now: DateTime(2026, 11, 3),
      );

  BtkRecord record(String id) => BtkRecord(id: id, date: DateTime(2026, 7, 1));

  test('it says what it covers, the filter, and that it holds no conclusions', () {
    final out = csv(
      [record('A')],
      total: 5,
      filter: RecordFilter(
        groups: const {'Tusheti'},
        dates: DateTimeRange(start: DateTime(2026), end: DateTime(2026, 12, 31)),
      ),
    );
    expect(out, contains('"Covers 1 of 5 records"'));
    expect(out, contains('"Tusheti"'));
    expect(out, contains('"2026-01-01 – 2026-12-31"'));
    expect(out, contains('not conclusions'));
  });

  test('each record keeps its own totals, with unreadable ones marked', () {
    final a = record('A')
      ..name = 'Omalo'
      ..altitude = 1880
      ..geomasses = [GeomassRow(pedomassQty: '10,5'), GeomassRow(lithomassQty: 'many')];
    final line = csv([a]).split('\r\n').firstWhere((l) => l.startsWith('"A"'));
    expect(line, startsWith('"A","Omalo","2026-07-01","1880","10.5","?",'));
  });

  test('the sections match the data, and empty ones are left out', () {
    final a = record('A')
      ..altitude = 120
      ..vegetation = [VegetationRow(tier: 'I', species: 'Fagus')];
    final out = csv([a], step: 100);
    expect(out, contains(l10n.statsVegStructure));
    expect(out, contains('"Altitude bands (m), 100"'));
    expect(out, contains('"100–200"'));
    expect(out, isNot(contains(l10n.statsHorizonFrequency)));
    expect(out, isNot(contains(l10n.statsDepthLayers)));
  });

  test('text can break neither the cells nor a spreadsheet', () {
    final a = record('A')..name = 'say "hi", =SUM(A1)';
    final b = record('B')..name = '=SUM(A1)';
    final c = record('C')..altitude = -20;
    final out = csv([a, b, c]);
    expect(out, contains('"say ""hi"", =SUM(A1)"'));
    expect(out, contains('"\'=SUM(A1)"'));
    expect(out, contains('"-20"'));
  });
}
