import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/btk_record.dart';
import '../domain/geomass_analytics.dart';
import '../domain/group_analytics.dart';
import '../domain/mass_chart_data.dart';
import '../domain/record_comparison.dart';

const _height = 240.0;
const _leftGutter = 48.0;
const _bottomGutter = 24.0;
const _topGutter = 8.0;
const _rightGutter = 12.0;
const _dotRadius = 5.0;
const _hitRadius = 24.0;

/// Every record as a dot. There is no trend line: a line through a few field
/// plots would read as a relationship the data can't support.
class MassChart extends StatefulWidget {
  final List<BtkRecord> records;

  const MassChart({super.key, required this.records});

  @override
  State<MassChart> createState() => _MassChartState();
}

class _MassChartState extends State<MassChart> {
  GeomassComponent? _component;
  ChartAxis _axis = ChartAxis.altitude;
  // Held by record, because the points are built anew on every rebuild.
  String? _selectedId;

  void _select(ChartPoint? point) {
    final id = point?.record.id;
    if (id != _selectedId) setState(() => _selectedId = id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 12, color: cs.onSurfaceVariant);

    final available = geomassComponents
        .where((c) => widget.records.any((r) => c.total(r) != null))
        .toList();
    if (available.isEmpty) return const SizedBox.shrink();
    final component =
        available.contains(_component) ? _component! : available.first;
    final series = chartSeries(widget.records, component, _axis);
    final selected =
        series.points.where((p) => p.record.id == _selectedId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.statsChart,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButton<GeomassComponent>(
          isExpanded: true,
          value: component,
          items: [
            for (final c in available)
              DropdownMenuItem(
                value: c,
                child: Text(c.label(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)),
              ),
          ],
          onChanged: (c) => setState(() {
            _component = c;
            _selectedId = null;
          }),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ChartAxis>(
          segments: [
            ButtonSegment(value: ChartAxis.altitude, label: Text(l10n.statsChartAltitude)),
            ButtonSegment(value: ChartAxis.date, label: Text(l10n.statsYear)),
          ],
          selected: {_axis},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() {
            _axis = v.first;
            _selectedId = null;
          }),
        ),
        const SizedBox(height: 8),
        if (series.points.length < 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(l10n.statsChartTooFew(series.points.length), style: muted),
          )
        else ...[
          Semantics(
            label: '${component.label(l10n)}: ${series.points.length}',
            child: _Plot(
              series: series,
              axis: _axis,
              selected: selected,
              onSelect: _select,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selected == null ? l10n.statsChartTap : _describe(selected, l10n),
            style: selected == null
                ? muted
                : const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
        if (series.noAltitude > 0)
          Text(l10n.statsChartNoAltitude(series.noAltitude), style: muted),
        if (series.unreadable > 0)
          Text(l10n.statsChartUnreadable(series.unreadable), style: muted),
        const SizedBox(height: 4),
        Text(l10n.statsChartNote, style: muted),
      ],
    );
  }

  String _describe(ChartPoint p, AppLocalizations l10n) {
    final name = p.record.name.isNotEmpty ? p.record.name : l10n.btkNumber(p.record.id);
    final x = _axis == ChartAxis.altitude
        ? '${shownNumber(p.x)} ${l10n.statsChartMetres}'
        : shortDate(p.record.date);
    return '$name · $x · ${shownNumber(p.y)}';
  }
}

class _Plot extends StatelessWidget {
  final ChartSeries series;
  final ChartAxis axis;
  final ChartPoint? selected;
  final ValueChanged<ChartPoint?> onSelect;

  const _Plot({
    required this.series,
    required this.axis,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final points = series.points;
    final xs = points.map((p) => p.x);
    final ys = points.map((p) => p.y);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final xTicks = niceTicks(
      xs.reduce((a, b) => a < b ? a : b),
      xs.reduce((a, b) => a > b ? a : b),
      // Altitude and years have no use for fractions of a tick.
      minStep: 1,
    );
    final yTicks = niceTicks(0, maxY == 0 ? 1 : maxY);

    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, _height);
      final scale = _Scale(size, xTicks, yTicks);

      ChartPoint? nearest(Offset at) {
        ChartPoint? best;
        var bestDistance = _hitRadius;
        for (final p in points) {
          final d = (scale.position(p) - at).distance;
          if (d < bestDistance) {
            bestDistance = d;
            best = p;
          }
        }
        return best;
      }

      return MouseRegion(
        onHover: (e) => onSelect(nearest(e.localPosition)),
        child: GestureDetector(
          onTapDown: (e) => onSelect(nearest(e.localPosition)),
          child: CustomPaint(
            size: size,
            painter: _PlotPainter(
              points: points,
              selected: selected,
              scale: scale,
              colors: Theme.of(context).colorScheme,
            ),
          ),
        ),
      );
    });
  }
}

class _Scale {
  final Size size;
  final List<double> xTicks;
  final List<double> yTicks;

  const _Scale(this.size, this.xTicks, this.yTicks);

  double x(double v) {
    final width = size.width - _leftGutter - _rightGutter;
    return _leftGutter +
        (v - xTicks.first) / (xTicks.last - xTicks.first) * width;
  }

  double y(double v) {
    final height = size.height - _topGutter - _bottomGutter;
    return _topGutter +
        height -
        (v - yTicks.first) / (yTicks.last - yTicks.first) * height;
  }

  Offset position(ChartPoint p) => Offset(x(p.x), y(p.y));
}

class _PlotPainter extends CustomPainter {
  final List<ChartPoint> points;
  final ChartPoint? selected;
  final _Scale scale;
  final ColorScheme colors;

  const _PlotPainter({
    required this.points,
    required this.selected,
    required this.scale,
    required this.colors,
  });

  void _text(Canvas canvas, String text, Offset at, {required bool alignRight}) {
    final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight ? at.dx - painter.width : at.dx - painter.width / 2;
    painter.paint(canvas, Offset(dx, at.dy - (alignRight ? painter.height / 2 : 0)));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = colors.outlineVariant.withValues(alpha: 0.6)
      ..strokeWidth = 0.5;
    final right = size.width - _rightGutter;
    final bottom = size.height - _bottomGutter;

    for (final t in scale.yTicks) {
      final y = scale.y(t);
      canvas.drawLine(Offset(_leftGutter, y), Offset(right, y), grid);
      _text(canvas, shownNumber(t), Offset(_leftGutter - 6, y), alignRight: true);
    }
    // Long axes would crowd a phone's width, so every other label is enough.
    final labelEvery = scale.xTicks.length > 6 ? 2 : 1;
    for (var i = 0; i < scale.xTicks.length; i++) {
      final x = scale.x(scale.xTicks[i]);
      canvas.drawLine(Offset(x, bottom), Offset(x, bottom + 3), grid);
      if (i % labelEvery == 0) {
        _text(canvas, shownNumber(scale.xTicks[i]), Offset(x, bottom + 5), alignRight: false);
      }
    }

    final ring = Paint()
      ..color = colors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dot = Paint()..color = colors.primary;
    for (final p in points) {
      final at = scale.position(p);
      canvas.drawCircle(at, _dotRadius, dot);
      canvas.drawCircle(at, _dotRadius + 1, ring);
    }
    final chosen = selected;
    if (chosen != null) {
      canvas.drawCircle(
        scale.position(chosen),
        _dotRadius + 3,
        Paint()
          ..color = colors.onSurface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_PlotPainter old) => true;
}
