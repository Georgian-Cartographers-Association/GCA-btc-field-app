import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

List<LatLng> _ring(List<dynamic> ring) => ring
    .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
    .toList();

List<List<LatLng>> _polygons(String raw) {
  final features = (jsonDecode(raw) as Map)['features'] as List;
  final polys = <List<LatLng>>[];
  for (final f in features) {
    final geom = f['geometry'] as Map;
    final coords = geom['coordinates'] as List;
    if (geom['type'] == 'Polygon') {
      polys.add(_ring(coords[0] as List));
    } else if (geom['type'] == 'MultiPolygon') {
      for (final poly in coords) {
        polys.add(_ring((poly as List)[0] as List));
      }
    }
  }
  return polys;
}

/// A place to search for, with the bounds of its shape as plain numbers.
class PlaceBounds {
  final String name;
  final double minLat, maxLat, minLon, maxLon;

  const PlaceBounds(this.name, this.minLat, this.maxLat, this.minLon, this.maxLon);
}

List<PlaceBounds> _places(({String raw, String field}) input) {
  final features = (jsonDecode(input.raw) as Map)['features'] as List;
  final places = <PlaceBounds>[];
  for (final f in features) {
    final name = ((f['properties'] as Map)[input.field] as String?) ?? '';
    if (name.isEmpty) continue;
    final geom = f['geometry'] as Map;
    final coords = geom['coordinates'] as List;
    final rings = geom['type'] == 'Polygon'
        ? [_ring(coords[0] as List)]
        : coords.map((p) => _ring((p as List)[0] as List)).toList();
    final pts = rings.expand((r) => r).toList();
    if (pts.isEmpty) continue;
    var minLat = pts[0].latitude, maxLat = pts[0].latitude;
    var minLon = pts[0].longitude, maxLon = pts[0].longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    places.add(PlaceBounds(name, minLat, maxLat, minLon, maxLon));
  }
  return places;
}

/// Parses boundary shapes away from the UI thread, since the files are large.
/// Web has no isolates, so there `compute` runs them in place.
Future<List<List<LatLng>>> parsePolygons(String raw) => compute(_polygons, raw);

Future<List<PlaceBounds>> parsePlaces(String raw, String field) =>
    compute(_places, (raw: raw, field: field));

@visibleForTesting
List<List<LatLng>> parsePolygonsNow(String raw) => _polygons(raw);

@visibleForTesting
List<PlaceBounds> parsePlacesNow(String raw, String field) =>
    _places((raw: raw, field: field));
