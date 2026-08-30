import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/btk_record.dart';
import '../../records/domain/btk_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(btkProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('სტატისტიკა')),
      body: records.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('ჩანაწერები არ არის',
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
    final located = records.where((r) => r.latitude != null).toList();
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary cards ───────────────────────────────────────────────────
        Row(children: [
          _Card(label: 'სულ', value: '${records.length}',
              icon: Icons.article_outlined, color: cs.primary),
          const SizedBox(width: 8),
          _Card(label: 'GPS', value: '${located.length}',
              icon: Icons.location_on_outlined, color: Colors.green),
          const SizedBox(width: 8),
          _Card(label: 'GPS გარეშე',
              value: '${records.length - located.length}',
              icon: Icons.location_off_outlined, color: Colors.orange),
        ]),
        const SizedBox(height: 20),

        // ── Monthly bars ────────────────────────────────────────────────────
        if (maxM > 0) ...[
          _SectionTitle('ბოლო 6 თვე'),
          const SizedBox(height: 8),
          _MonthlyBars(monthly: monthly, max: maxM, color: cs.primary),
          const SizedBox(height: 20),
        ],

        // ── Geological formations ───────────────────────────────────────────
        if (geoFreq.isNotEmpty) ...[
          _SectionTitle('გეოლოგიური ფორმაციები'),
          const SizedBox(height: 8),
          _FreqBars(entries: geoFreq.take(5).toList(), color: cs.primary),
          const SizedBox(height: 20),
        ],

        // ── Relief types ────────────────────────────────────────────────────
        if (reliefFreq.isNotEmpty) ...[
          _SectionTitle('რელიეფის ტიპები'),
          const SizedBox(height: 8),
          _FreqBars(entries: reliefFreq.take(5).toList(), color: cs.tertiary),
          const SizedBox(height: 20),
        ],

        // ── Soil types ──────────────────────────────────────────────────────
        if (soilFreq.isNotEmpty) ...[
          _SectionTitle('ნიადაგის ტიპები'),
          const SizedBox(height: 8),
          _FreqBars(entries: soilFreq.take(5).toList(), color: Colors.brown),
          const SizedBox(height: 20),
        ],

        // ── Mini map ────────────────────────────────────────────────────────
        if (located.isNotEmpty) ...[
          _SectionTitle('ჩანაწერები რუქაზე (${located.length})'),
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
          userAgentPackageName: 'ge.gca.btk_field_app',
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

// ── Helpers ───────────────────────────────────────────────────────────────────

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
