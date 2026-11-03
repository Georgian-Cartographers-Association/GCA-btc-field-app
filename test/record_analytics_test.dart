import 'package:btk_field_app/features/stats/domain/record_analytics.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter_test/flutter_test.dart';

BtkRecord _record(String id) => BtkRecord(id: id, date: DateTime(2026, 7, 1));

void main() {
  test('records with only blank rows count as having no data', () {
    final a = _record('A')
      ..vegetation = [VegetationRow()]
      ..soilHorizons = [SoilHorizonRow()];
    final result = RecordAnalytics.of([a, _record('B')]);
    expect(result.hasVegetation, isFalse);
    expect(result.hasHorizons, isFalse);
    expect(result.tiers, isEmpty);
  });

  test('a tier counts each record once and its species without repeats', () {
    final a = _record('A')
      ..vegetation = [
        VegetationRow(tier: 'I', species: 'Fagus orientalis'),
        VegetationRow(tier: 'I', species: 'fagus orientalis, Abies nordmanniana'),
      ];
    final b = _record('B')..vegetation = [VegetationRow(tier: ' i ', species: 'Carpinus')];
    final tier = RecordAnalytics.of([a, b]).tiers.single;
    expect(tier.tier, 'I');
    expect(tier.records, 2);
    expect(tier.species, 3);
  });

  test('unreadable heights stay out of the range and are counted', () {
    final a = _record('A')
      ..vegetation = [
        VegetationRow(tier: 'I', height: '12'),
        VegetationRow(tier: 'I', height: '30 მ'),
        VegetationRow(tier: 'I', height: 'მაღალი'),
        VegetationRow(tier: 'I', species: 'Fagus'),
      ];
    final tier = RecordAnalytics.of([a]).tiers.single;
    expect(tier.minHeight, 12);
    expect(tier.maxHeight, 30);
    expect(tier.unreadableHeights, 1);
  });

  test('rows without a tier are kept and listed last', () {
    final a = _record('A')
      ..vegetation = [VegetationRow(species: 'Fagus'), VegetationRow(tier: 'II', species: 'Abies')];
    expect(RecordAnalytics.of([a]).tiers.map((t) => t.tier), ['II', '']);
  });

  test('a species named twice in one record counts for one record', () {
    final a = _record('A')
      ..vegetation = [VegetationRow(species: 'Fagus'), VegetationRow(species: 'FAGUS; Abies')];
    final b = _record('B')..vegetation = [VegetationRow(species: 'fagus')];
    final species = RecordAnalytics.of([a, b]).species;
    expect(species.map((e) => e.key), ['Fagus', 'Abies']);
    expect(species.map((e) => e.value), [2, 1]);
  });

  test('horizons keep their case, and orders are counted whole', () {
    BtkRecord withHorizons(String id, List<String> names) => _record(id)
      ..soilHorizons = [for (final n in names) SoilHorizonRow(horizon: n)];
    final result = RecordAnalytics.of([
      withHorizons('A', ['Ah', 'B', 'C']),
      withHorizons('B', ['Ah', 'B', 'C']),
      withHorizons('C', ['AH', 'B', 'B']),
    ]);
    expect(result.recordsWithHorizons, 3);
    expect(Map.fromEntries(result.horizons), {'B': 3, 'Ah': 2, 'C': 2, 'AH': 1});
    expect(result.horizonOrders.first.key, 'Ah → B → C');
    expect(result.horizonOrders.first.value, 2);
    expect(result.horizonOrders.last.key, 'AH → B → B');
  });

  test('old records without these rows still load into the analysis', () {
    final old = BtkRecord.fromJson({'id': 'old', 'date': '2020-05-01T00:00:00.000'});
    expect(RecordAnalytics.of([old]).hasVegetation, isFalse);
  });
}
