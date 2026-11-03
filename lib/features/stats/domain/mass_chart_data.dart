import 'dart:math' as math;

import '../../../models/btk_record.dart';
import 'geomass_analytics.dart';

enum ChartAxis { altitude, date }

/// One record's total of a mass, placed on the chart.
class ChartPoint {
  final BtkRecord record;
  final double x;
  final double y;

  const ChartPoint(this.record, this.x, this.y);
}

/// The points for one mass, with a count of what couldn't be drawn, so the chart
/// doesn't look like all the data when it isn't.
class ChartSeries {
  final List<ChartPoint> points;
  final int noAltitude;
  final int unreadable;

  const ChartSeries(this.points, this.noAltitude, this.unreadable);
}

// A date as a fractional year, so records spread out within the year's tick.
double _yearOf(DateTime d) =>
    d.year + d.difference(DateTime(d.year)).inDays / 366;

ChartSeries chartSeries(
    List<BtkRecord> records, GeomassComponent component, ChartAxis axis) {
  final points = <ChartPoint>[];
  var noAltitude = 0;
  var unreadable = 0;
  for (final r in records) {
    final total = component.total(r);
    if (total == null) continue;
    final y = total.value;
    if (y == null) {
      unreadable++;
      continue;
    }
    final x = axis == ChartAxis.altitude ? r.altitude : _yearOf(r.date);
    if (x == null) {
      noAltitude++;
      continue;
    }
    points.add(ChartPoint(r, x, y));
  }
  return ChartSeries(points, noAltitude, unreadable);
}

/// Round axis values covering [low] to [high], never closer than [minStep].
List<double> niceTicks(double low, double high, {double minStep = 0}) {
  if (high <= low) {
    low -= 1;
    high += 1;
  }
  final rough = (high - low) / 4;
  final power = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final fraction = rough / power;
  final nice = fraction <= 1
      ? 1
      : fraction <= 2
          ? 2
          : fraction <= 5
              ? 5
              : 10;
  final step = math.max(nice * power, minStep);
  final first = (low / step).floor();
  final last = (high / step).ceil();
  return [for (var i = first; i <= last; i++) i * step];
}
