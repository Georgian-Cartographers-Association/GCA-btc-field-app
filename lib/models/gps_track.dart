import 'dart:convert';
import 'package:latlong2/latlong.dart';

class GpsPoint {
  final double lat;
  final double lon;
  final double altitude;
  final DateTime time;

  /// Horizontal accuracy in metres. Points from before 1.22 don't have it.
  final double? accuracy;

  const GpsPoint({
    required this.lat,
    required this.lon,
    required this.altitude,
    required this.time,
    this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'alt': altitude,
        'time': time.toIso8601String(),
        if (accuracy != null) 'acc': accuracy,
      };

  factory GpsPoint.fromJson(Map<String, dynamic> j) => GpsPoint(
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        altitude: (j['alt'] as num?)?.toDouble() ?? 0,
        time: DateTime.parse(j['time'] as String),
        accuracy: (j['acc'] as num?)?.toDouble(),
      );
}

class GpsTrack {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<GpsPoint> points;

  const GpsTrack({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.points = const [],
  });

  GpsTrack copyWith({DateTime? endedAt, List<GpsPoint>? points}) => GpsTrack(
        id: id,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        points: points ?? this.points,
      );

  /// The point closest to the given place, or null if there are no points.
  GpsPoint? nearestTo(double lat, double lon) {
    const calc = Distance();
    final here = LatLng(lat, lon);
    GpsPoint? best;
    var bestDistance = double.infinity;
    for (final p in points) {
      final d = calc(here, LatLng(p.lat, p.lon));
      if (d < bestDistance) {
        best = p;
        bestDistance = d;
      }
    }
    return best;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'points_json': jsonEncode(points.map((p) => p.toJson()).toList()),
      };

  /// One damaged point is skipped, so it can't cost the rest of the track.
  factory GpsTrack.fromMap(Map<String, dynamic> m) {
    final pts = <GpsPoint>[];
    for (final e in jsonDecode(m['points_json'] as String) as List<dynamic>) {
      try {
        pts.add(GpsPoint.fromJson(Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    }
    return GpsTrack(
      id: m['id'] as String,
      startedAt: DateTime.parse(m['started_at'] as String),
      endedAt: m['ended_at'] != null
          ? DateTime.parse(m['ended_at'] as String)
          : null,
      points: pts,
    );
  }
}
