import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../../../../utils/measurement_service.dart';
import '../../../../utils/utm_service.dart';

class MeasurementPanel extends StatelessWidget {
  final MeasureMode mode;
  final List<LatLng> points;
  final ValueChanged<MeasureMode> onModeChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const MeasurementPanel({
    super.key,
    required this.mode,
    required this.points,
    required this.onModeChanged,
    required this.onUndo,
    required this.onClear,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: [
                // Mode selector
                _ModeButton(
                  icon: Icons.location_on_outlined,
                  label: 'კოორდ.',
                  active: mode == MeasureMode.coordinate,
                  onTap: () => onModeChanged(MeasureMode.coordinate),
                ),
                const SizedBox(width: 6),
                _ModeButton(
                  icon: Icons.straighten,
                  label: 'ხაზი',
                  active: mode == MeasureMode.line,
                  onTap: () => onModeChanged(MeasureMode.line),
                ),
                const SizedBox(width: 6),
                _ModeButton(
                  icon: Icons.hexagon_outlined,
                  label: 'პოლიგ.',
                  active: mode == MeasureMode.polygon,
                  onTap: () => onModeChanged(MeasureMode.polygon),
                ),
                const Spacer(),
                // Action buttons
                if (points.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.undo, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'გაუქმება',
                    onPressed: onUndo,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'გასუფთავება',
                    onPressed: onClear,
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'დახურვა',
                  onPressed: onClose,
                ),
              ],
            ),

            if (points.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _hint(mode),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),

            // ── Results ────────────────────────────────────────────────────
            if (points.isNotEmpty) ...[
              const Divider(height: 12),
              _buildResults(context),
            ],
          ],
        ),
      ),
    );
  }

  String _hint(MeasureMode m) {
    switch (m) {
      case MeasureMode.coordinate:
        return 'რუკაზე შეეხეთ კოორდინატების სანახავად';
      case MeasureMode.line:
        return 'შეეხეთ წერტილების დასამატებლად';
      case MeasureMode.polygon:
        return 'შეეხეთ პოლიგონის ასაგებად (მინ. 3 წ.)';
      case MeasureMode.none:
        return '';
    }
  }

  Widget _buildResults(BuildContext context) {
    switch (mode) {
      case MeasureMode.coordinate:
        return _buildCoordResults(context);
      case MeasureMode.line:
        return _buildLineResults(context);
      case MeasureMode.polygon:
        return _buildPolygonResults(context);
      case MeasureMode.none:
        return const SizedBox();
    }
  }

  Widget _buildCoordResults(BuildContext context) {
    if (points.isEmpty) return const SizedBox();
    final p = points.last;
    final utm = UtmService.toUtm38N(p.latitude, p.longitude);
    final wgs = MeasurementService.formatWgs84(p.latitude, p.longitude);
    final utmStr = utm.formatted();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResultRow(label: 'WGS84', value: wgs, copyValue: wgs),
        _ResultRow(label: 'UTM 38N', value: utmStr, copyValue: utmStr),
      ],
    );
  }

  Widget _buildLineResults(BuildContext context) {
    if (points.length < 2) {
      return _ResultRow(
          label: 'წ.', value: '${points.length}', copyValue: '${points.length}');
    }
    final len = MeasurementService.totalLength(points);
    final lenStr = MeasurementService.formatLength(len);
    return _ResultRow(label: 'სიგრძე', value: lenStr, copyValue: lenStr);
  }

  Widget _buildPolygonResults(BuildContext context) {
    final rows = <Widget>[];
    rows.add(_ResultRow(
        label: 'წ.',
        value: '${points.length}',
        copyValue: '${points.length}'));
    if (points.length >= 2) {
      final per = MeasurementService.polygonPerimeter(points);
      final perStr = MeasurementService.formatLength(per);
      rows.add(_ResultRow(label: 'პერიმეტრი', value: perStr, copyValue: perStr));
    }
    if (points.length >= 3) {
      final area = MeasurementService.polygonArea(points);
      final areaStr = MeasurementService.formatArea(area);
      rows.add(_ResultRow(label: 'ფართობი', value: areaStr, copyValue: areaStr));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16,
                color: active ? scheme.primary : scheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? scheme.primary : scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final String copyValue;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.copyValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: copyValue));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('კოპირებულია 📋'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Row(
          children: [
            SizedBox(
              width: 78,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            ),
            const Icon(Icons.copy, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
