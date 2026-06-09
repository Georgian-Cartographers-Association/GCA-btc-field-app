import 'package:latlong2/latlong.dart';
import '../../models/gps_track.dart';
import 'duration_extensions.dart';

extension GpsTrackX on GpsTrack {
  /// Haversine distance across all track points, formatted as "1.23 კმ" or "456 მ".
  String get formattedDistance {
    if (points.length < 2) return '0 მ';
    const calc = Distance();
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += calc(
        LatLng(points[i - 1].lat, points[i - 1].lon),
        LatLng(points[i].lat, points[i].lon),
      );
    }
    return total >= 1000
        ? '${(total / 1000).toStringAsFixed(2)} კმ'
        : '${total.toStringAsFixed(0)} მ';
  }

  /// Formatted recording duration, or "—" if still active.
  String get formattedDuration {
    if (endedAt == null) return '—';
    return endedAt!.difference(startedAt).toGeorgianString();
  }
}
