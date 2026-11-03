import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../core/constants.dart';

const _tileSize = 256;
const _zoom = 14;
const _timeout = Duration(seconds: 6);

/// The map's size on the page, in tile pixels.
const pdfMapWidth = 512;
const pdfMapHeight = 220;

/// OpenStreetMap's tile servers don't allow bulk downloads, so one PDF stops
/// asking at this many tiles. Tiles shared by nearby records count once.
const pdfMapTileLimit = 60;

/// Returns a tile's PNG bytes, or throws if it can't be had.
typedef TileFetcher = Future<Uint8List> Function(int zoom, int x, int y);

/// A tile and where its top left corner falls in the map, in tile pixels.
class PlacedTile {
  final Uint8List bytes;
  final double left;
  final double top;

  const PlacedTile(this.bytes, this.left, this.top);
}

class TilePosition {
  final int x;
  final int y;
  final double left;
  final double top;

  const TilePosition(this.x, this.y, this.left, this.top);
}

/// The tiles that fill a map centred on the point, which is null where the map
/// projection has nothing to show, near the poles.
List<TilePosition>? tilesAround(double lat, double lon) {
  if (lat.abs() > 85) return null;
  final worldTiles = 1 << _zoom;
  final radians = lat * math.pi / 180;
  final centreX = (lon + 180) / 360 * worldTiles * _tileSize;
  final centreY = (1 - math.log(math.tan(radians) + 1 / math.cos(radians)) / math.pi) /
      2 *
      worldTiles *
      _tileSize;
  final left = centreX - pdfMapWidth / 2;
  final top = centreY - pdfMapHeight / 2;

  final firstX = (left / _tileSize).floor();
  final lastX = ((left + pdfMapWidth - 1) / _tileSize).floor();
  final firstY = (top / _tileSize).floor();
  final lastY = ((top + pdfMapHeight - 1) / _tileSize).floor();

  return [
    for (var y = firstY; y <= lastY; y++)
      for (var x = firstX; x <= lastX; x++)
        if (y >= 0 && y < worldTiles)
          TilePosition(
            // Across the date line the same tiles repeat.
            x % worldTiles,
            y,
            x * _tileSize - left,
            y * _tileSize - top,
          ),
  ];
}

Future<Uint8List> _fetchFromOsm(int zoom, int x, int y) async {
  final url = AppConstants.osmTileUrl
      .replaceAll('{z}', '$zoom')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$y');
  final response = await http.get(
    Uri.parse(url),
    // A browser sets its own and refuses this one.
    headers: kIsWeb ? null : const {'User-Agent': 'ge.btc.field_app'},
  ).timeout(_timeout);
  if (response.statusCode != 200) throw Exception('tile ${response.statusCode}');
  return response.bodyBytes;
}

bool _isPng(Uint8List b) =>
    b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;

/// Loads maps for one PDF. A map is an extra: the first failure, which usually
/// means no network, ends the attempts, so an offline PDF isn't held up by a
/// timeout per record and is otherwise the same.
class PdfMapLoader {
  final TileFetcher _fetch;
  final Map<String, Uint8List> _tiles = {};
  bool _stopped = false;
  int _requests = 0;

  PdfMapLoader({TileFetcher? fetch}) : _fetch = fetch ?? _fetchFromOsm;

  /// Null when any tile of the map is missing, since a map with holes misleads.
  Future<List<PlacedTile>?> load(double lat, double lon) async {
    if (_stopped) return null;
    final positions = tilesAround(lat, lon);
    if (positions == null) return null;

    String keyOf(TilePosition p) => '${p.x}/${p.y}';
    final missing = positions.where((p) => !_tiles.containsKey(keyOf(p))).toList();
    if (_requests + missing.length > pdfMapTileLimit) {
      _stopped = true;
      return null;
    }
    _requests += missing.length;

    try {
      await Future.wait(missing.map((p) async {
        final bytes = await _fetch(_zoom, p.x, p.y);
        if (!_isPng(bytes)) throw const FormatException('not a PNG');
        _tiles[keyOf(p)] = bytes;
      }));
    } catch (_) {
      _stopped = true;
      return null;
    }
    return [for (final p in positions) PlacedTile(_tiles[keyOf(p)]!, p.left, p.top)];
  }
}
