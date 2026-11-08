import 'dart:convert';

import 'package:btk_field_app/data/services/statistics_pdf.dart';
import 'package:btk_field_app/features/records/domain/record_filter.dart';
import 'package:btk_field_app/features/stats/domain/results_export.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BtkRecord _record(String id, double? altitude, String pedomass, [int year = 2026]) =>
    BtkRecord(id: id, date: DateTime(year, 7, 1))
      ..altitude = altitude
      ..geomasses = [GeomassRow(pedomassQty: pedomass)];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<List<int>> pdf(List<BtkRecord> records) => buildStatisticsPdf(
        records: records,
        totalRecords: records.length,
        filter: const RecordFilter(),
        bandStep: 500,
        l10n: l10n,
        now: DateTime(2026, 11, 3),
      );

  test('it builds with charts, and with too little data for any', () async {
    final many = await pdf([
      _record('A', 1000, '10', 2024),
      _record('B', 2000, '20', 2025),
      _record('C', null, 'many'),
    ]);
    expect(latin1.decode(many.sublist(0, 4)), '%PDF');
    final few = await pdf([_record('A', 1000, '10')]);
    expect(latin1.decode(few.sublist(0, 4)), '%PDF');
    expect(many.length, greaterThan(few.length));
  });

  test('every point sharing one altitude still draws', () async {
    final out = await pdf([_record('A', 1880, '10'), _record('B', 1880, '0')]);
    expect(out, isNotEmpty);
  });

  test('all totals of zero still draw', () async {
    final out = await pdf([_record('A', 100, '0'), _record('B', 200, '0')]);
    expect(out, isNotEmpty);
  });

  test('a large set of records runs over several pages', () async {
    final out = await pdf([
      for (var i = 0; i < 200; i++) _record('$i', 500.0 + i * 10, '${10 + i}', 2020 + i % 7),
    ]);
    expect(RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(out)).length, greaterThan(1));
  });

  test('the report and the CSV list the same tables', () {
    final tables = resultTables(
      records: [_record('A', 100, '10')],
      bandStep: 500,
      l10n: l10n,
    );
    final csv = buildResultsCsv(
      records: [_record('A', 100, '10')],
      totalRecords: 1,
      filter: const RecordFilter(),
      bandStep: 500,
      l10n: l10n,
      now: DateTime(2026),
    );
    expect(tables, isNotEmpty);
    expect(tables.every((t) => t.rows.isNotEmpty), isTrue);
    for (final t in tables) {
      expect(csv, contains('"${t.title}"'));
    }
  });
}
