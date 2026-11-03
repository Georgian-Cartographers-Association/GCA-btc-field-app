import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/btk_record.dart';
import '../../records/domain/record_filter.dart';
import '../../records/domain/btk_provider.dart';
import '../domain/geomass_analytics.dart';
import '../domain/record_analytics.dart';
import '../domain/record_comparison.dart';
import '../../../l10n/generated/app_localizations.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final records = ref.watch(btkProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statistics)),
      body: records.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(l10n.noRecordsYet,
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _StatsBody(records: records),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final List<BtkRecord> records;
  const _StatsBody({required this.records});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final located = records.where((r) => r.mapPoint != null).toList();
    final cs = Theme.of(context).colorScheme;

    // Frequency maps
    final geoFreq = _freq(records.map((r) => r.geologicalFormation));
    final reliefFreq = _freq(records.map((r) => r.reliefType));
    final soilFreq = _freq(records.map((r) => r.soilTypeName));

    // Monthly counts — last 6 months
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return (year: d.year, month: d.month);
    }).reversed.toList();
    final monthly = {
      for (final m in months)
        '${m.year}-${m.month.toString().padLeft(2, '0')}': records
            .where((r) => r.date.year == m.year && r.date.month == m.month)
            .length,
    };
    final maxM = monthly.values.fold(0, (a, b) => a > b ? a : b);
    final analytics = RecordAnalytics.of(records);
    final geomass = GeomassAnalytics.of(records);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary cards ───────────────────────────────────────────────────
        Row(children: [
          _Card(label: l10n.statsTotal, value: '${records.length}',
              icon: Icons.article_outlined, color: cs.primary),
          const SizedBox(width: 8),
          _Card(label: 'GPS', value: '${located.length}',
              icon: Icons.location_on_outlined, color: Colors.green),
          const SizedBox(width: 8),
          _Card(label: l10n.statsNoGps,
              value: '${records.length - located.length}',
              icon: Icons.location_off_outlined, color: Colors.orange),
        ]),
        const SizedBox(height: 20),

        // ── Monthly bars ────────────────────────────────────────────────────
        if (maxM > 0) ...[
          _SectionTitle(l10n.statsLast6Months),
          const SizedBox(height: 8),
          _MonthlyBars(monthly: monthly, max: maxM, color: cs.primary),
          const SizedBox(height: 20),
        ],

        // ── Geological formations ───────────────────────────────────────────
        if (geoFreq.isNotEmpty) ...[
          _SectionTitle(l10n.statsGeoFormations),
          const SizedBox(height: 8),
          _FreqBars(entries: geoFreq.take(5).toList(), color: cs.primary),
          const SizedBox(height: 20),
        ],

        // ── Relief types ────────────────────────────────────────────────────
        if (reliefFreq.isNotEmpty) ...[
          _SectionTitle(l10n.statsReliefTypes),
          const SizedBox(height: 8),
          _FreqBars(entries: reliefFreq.take(5).toList(), color: cs.tertiary),
          const SizedBox(height: 20),
        ],

        // ── Soil types ──────────────────────────────────────────────────────
        if (soilFreq.isNotEmpty) ...[
          _SectionTitle(l10n.statsSoilTypes),
          const SizedBox(height: 8),
          _FreqBars(entries: soilFreq.take(5).toList(), color: Colors.brown),
          const SizedBox(height: 20),
        ],

        // ── Vegetation structure ────────────────────────────────────────────
        if (analytics.hasVegetation) ...[
          _SectionTitle(l10n.statsVegStructure),
          _DataShare(count: analytics.recordsWithVegetation, total: records.length),
          const SizedBox(height: 8),
          _TierTable(tiers: analytics.tiers),
          if (analytics.species.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SubTitle(l10n.statsSpeciesFrequency),
            _LongFreqBars(entries: analytics.species, color: Colors.green),
          ],
          const SizedBox(height: 20),
        ],

        // ── Soil horizons ───────────────────────────────────────────────────
        if (analytics.hasHorizons) ...[
          _SectionTitle(l10n.statsSoilHorizons),
          _DataShare(count: analytics.recordsWithHorizons, total: records.length),
          const SizedBox(height: 8),
          _SubTitle(l10n.statsHorizonFrequency),
          _LongFreqBars(entries: analytics.horizons, color: Colors.brown),
          const SizedBox(height: 12),
          _SubTitle(l10n.statsHorizonOrders),
          _LongFreqBars(entries: analytics.horizonOrders, color: Colors.brown),
          const SizedBox(height: 20),
        ],

        // ── Geomass ─────────────────────────────────────────────────────────
        if (geomass.hasData) ...[
          _SectionTitle(l10n.statsGeomass),
          _DataShare(count: geomass.recordsWithData, total: records.length),
          const SizedBox(height: 8),
          if (geomass.components.isNotEmpty) ...[
            _SubTitle(l10n.statsGeomassTotals),
            _ComponentTable(components: geomass.components),
            const SizedBox(height: 12),
          ],
          if (geomass.layers.isNotEmpty) ...[
            _SubTitle(l10n.statsDepthLayers),
            _LayerTable(layers: geomass.layers),
            const SizedBox(height: 8),
          ],
          Text(l10n.statsGeomassNote,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),
        ],

        if (analytics.hasVegetation || analytics.hasHorizons) ...[
          Text(l10n.statsAnalysisNote,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),
        ],

        // ── Mini map ────────────────────────────────────────────────────────
        if (located.isNotEmpty) ...[
          _SectionTitle(l10n.recordsOnMap(located.length)),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _MiniMap(records: located, color: cs.primary),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  static List<MapEntry<String, int>> _freq(Iterable<String> values) {
    final map = <String, int>{};
    for (final v in values) {
      if (v.isNotEmpty) map[v] = (map[v] ?? 0) + 1;
    }
    return (map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }
}

// ── Mini map ────────────────────────────────────────────────────────────────

class _MiniMap extends StatelessWidget {
  final List<BtkRecord> records;
  final Color color;
  const _MiniMap({required this.records, required this.color});

  @override
  Widget build(BuildContext context) {
    final lats = records.map((r) => r.latitude!);
    final lons = records.map((r) => r.longitude!);
    final centerLat =
        (lats.reduce((a, b) => a + b)) / records.length;
    final centerLon =
        (lons.reduce((a, b) => a + b)) / records.length;

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLon),
        initialZoom: records.length == 1 ? 13 : 8,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'ge.btc.field_app',
        ),
        MarkerLayer(
          markers: records
              .map((r) => Marker(
                    point: LatLng(r.latitude!, r.longitude!),
                    width: 14,
                    height: 14,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: const Offset(0, 1))
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ── Chart widgets ────────────────────────────────────────────────────────────

class _MonthlyBars extends StatelessWidget {
  final Map<String, int> monthly;
  final int max;
  final Color color;
  const _MonthlyBars(
      {required this.monthly, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: monthly.entries.map((e) {
            final frac = max > 0 ? e.value / max : 0.0;
            final label = e.key.substring(5); // MM
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (e.value > 0)
                      Text('${e.value}',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Container(
                      height: 80 * frac + 4,
                      decoration: BoxDecoration(
                        color: frac > 0
                            ? color.withValues(alpha:0.7 + frac * 0.3)
                            : Colors.grey.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FreqBars extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final Color color;
  const _FreqBars({required this.entries, required this.color});

  @override
  Widget build(BuildContext context) {
    final max = entries.isEmpty ? 1 : entries.first.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: entries.map((e) {
            final frac = e.value / max;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      e.key,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 14,
                        backgroundColor: Colors.grey.withValues(alpha:0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color.withValues(alpha:0.8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    child: Text('${e.value}',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// [_FreqBars] for lists that can run long, saying how many were left out.
class _LongFreqBars extends StatelessWidget {
  static const _shown = 10;

  final List<MapEntry<String, int>> entries;
  final Color color;
  const _LongFreqBars({required this.entries, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hidden = entries.length - _shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FreqBars(entries: entries.take(_shown).toList(), color: color),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Text(l10n.statsMoreItems(hidden),
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
      ],
    );
  }
}

Widget _cell(String? text, {bool bold = false}) => Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text ?? '—',
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );

class _ComponentTable extends StatelessWidget {
  final List<ComponentSummary> components;
  const _ComponentTable({required this.components});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(5),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(4),
          },
          children: [
            TableRow(children: [
              _cell(l10n.statsGeomassComponent, bold: true),
              _cell(l10n.statsTierRecords, bold: true),
              _cell(l10n.statsGeomassRange, bold: true),
            ]),
            for (final c in components)
              TableRow(children: [
                _cell(c.component.label(l10n)),
                _cell('${c.records}'),
                _cell(c.totals.text),
              ]),
          ],
        ),
      ),
    );
  }
}

class _LayerTable extends StatelessWidget {
  final List<DepthLayer> layers;
  const _LayerTable({required this.layers});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(6),
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(84),
          columnWidths: const {
            0: FixedColumnWidth(64),
            1: FixedColumnWidth(54),
          },
          children: [
            TableRow(children: [
              _cell(l10n.statsDepthLayer, bold: true),
              _cell(l10n.statsTierRecords, bold: true),
              for (final c in layerColumns) _cell(c.label(l10n), bold: true),
            ]),
            for (final layer in layers)
              TableRow(children: [
                _cell(layer.text ?? l10n.statsDepthUnknown),
                _cell('${layer.records}'),
                for (final v in layer.values) _cell(v.text),
              ]),
          ],
        ),
      ),
    );
  }
}

class _TierTable extends StatelessWidget {
  final List<TierSummary> tiers;
  const _TierTable({required this.tiers});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(3),
          },
          children: [
            TableRow(children: [
              _cell(l10n.vegTier, bold: true),
              _cell(l10n.statsTierRecords, bold: true),
              _cell(l10n.statsTierSpecies, bold: true),
              _cell(l10n.vegHeightM, bold: true),
            ]),
            for (final t in tiers)
              TableRow(children: [
                _cell(t.tier.isEmpty ? l10n.statsNoTier : t.tier),
                _cell('${t.records}'),
                _cell('${t.species}'),
                _cell(rangeText(t.minHeight, t.maxHeight, t.unreadableHeights)),
              ]),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _DataShare extends StatelessWidget {
  final int count;
  final int total;
  const _DataShare({required this.count, required this.total});

  @override
  Widget build(BuildContext context) => Text(
        AppLocalizations.of(context)!.statsRecordsWithData(count, total),
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      );
}

class _SubTitle extends StatelessWidget {
  final String text;
  const _SubTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      );
}

class _Card extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Card(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      );
}
