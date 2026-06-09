import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/map_provider.dart';

class LayerControlPanel extends ConsumerWidget {
  const LayerControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layers = ref.watch(mapLayersProvider);
    final n = ref.read(mapLayersProvider.notifier);

    // SafeArea bottom padding (browser chrome, home bar, etc.)
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('შრეების კონტროლი',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // ── ფონური რუკები ────────────────────────────────────────
            _SectionLabel('ფონური რუკები'),
            _LayerTile(
              icon: Icons.map_outlined,
              label: 'OpenStreetMap',
              value: layers.showOsm,
              onChanged: (_) => n.toggleOsm(),
            ),
            _LayerTile(
              icon: Icons.terrain,
              label: 'OpenTopoMap',
              value: layers.showTopo,
              onChanged: (_) => n.toggleTopo(),
            ),

            const Divider(height: 24),

            // ── ადმინისტრაციული საზღვრები ────────────────────────────
            _SectionLabel('ადმინისტრაციული საზღვრები'),
            _LayerTile(
              icon: Icons.pentagon_outlined,
              label: 'საქართველოს საზღვარი',
              value: layers.showBoundary,
              color: Colors.blue.shade700,
              onChanged: (_) => n.toggleBoundary(),
            ),
            _LayerTile(
              icon: Icons.grid_view_outlined,
              label: 'მხარეები',
              value: layers.showRegions,
              color: Colors.orange.shade700,
              onChanged: (_) => n.toggleRegions(),
            ),
            _LayerTile(
              icon: Icons.grid_on_outlined,
              label: 'მუნიციპალიტეტები',
              value: layers.showMunicipalities,
              color: Colors.green.shade700,
              onChanged: (_) => n.toggleMunicipalities(),
            ),

            const Divider(height: 24),

            // ── საველე მონაცემები ─────────────────────────────────────
            _SectionLabel('საველე მონაცემები'),
            _LayerTile(
              icon: Icons.location_pin,
              label: 'ბტკ წერტილები',
              value: layers.showPoints,
              color: Theme.of(context).colorScheme.primary,
              onChanged: (_) => n.togglePoints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _LayerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color? color;
  final ValueChanged<bool> onChanged;

  const _LayerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.onSurface;
    return SwitchListTile(
      secondary: Icon(icon, color: value ? iconColor : iconColor.withValues(alpha: 0.35)),
      title: Text(
        label,
        style: TextStyle(
          color: value
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
