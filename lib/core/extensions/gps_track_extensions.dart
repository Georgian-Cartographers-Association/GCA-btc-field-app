import 'package:latlong2/latlong.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/gps_track.dart';
import 'duration_extensions.dart';

extension GpsTrackX on GpsTrack {
  /// Haversine distance across all track points, formatted as "1.23 km" or "456 m".
  String formattedDistance(AppLocalizations l10n) {
    if (points.length < 2) return '0 ${l10n.unitM}';
    const calc = Distance();
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += calc(
        LatLng(points[i - 1].lat, points[i - 1].lon),
        LatLng(points[i].lat, points[i].lon),
      );
    }
    return total >= 1000
        ? '${(total / 1000).toStringAsFixed(2)} ${l10n.unitKm}'
        : '${total.toStringAsFixed(0)} ${l10n.unitM}';
  }

  /// Formatted recording duration, or "—" if still active.
  String formattedDuration(AppLocalizations l10n) {
    if (endedAt == null) return '—';
    return endedAt!.difference(startedAt).toLocalizedString(l10n);
  }
}
