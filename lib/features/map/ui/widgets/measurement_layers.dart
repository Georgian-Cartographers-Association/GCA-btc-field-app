import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../utils/measurement_service.dart';

List<Widget> buildMeasurementLayers({
  required MeasureMode mode,
  required List<LatLng> points,
  required ColorScheme scheme,
}) {
  if (mode == MeasureMode.none || points.isEmpty) return const [];

  final layers = <Widget>[];
  final color = scheme.primary;

  // ── Polygon fill ──────────────────────────────────────────────────────────
  if (mode == MeasureMode.polygon && points.length >= 3) {
    layers.add(PolygonLayer(
      polygons: [
        Polygon(
          points: points,
          color: color.withValues(alpha: 0.15),
          borderColor: color,
          borderStrokeWidth: 2.0,
        ),
      ],
    ));
  }

  // ── Polyline ──────────────────────────────────────────────────────────────
  if (points.length >= 2) {
    final linePoints = (mode == MeasureMode.polygon && points.length >= 3)
        ? [...points, points.first]
        : points;
    layers.add(PolylineLayer(
      polylines: [
        Polyline(
          points: linePoints,
          strokeWidth: 2.5,
          color: color,
        ),
      ],
    ));
  }

  // ── Numbered markers ──────────────────────────────────────────────────────
  layers.add(MarkerLayer(
    markers: points.asMap().entries.map((e) {
      return Marker(
        point: e.value,
        width: 26,
        height: 26,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 3)
            ],
          ),
          child: Center(
            child: Text(
              '${e.key + 1}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1),
            ),
          ),
        ),
      );
    }).toList(),
  ));

  return layers;
}
