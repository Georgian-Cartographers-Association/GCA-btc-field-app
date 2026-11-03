import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:btk_field_app/data/services/export_service.dart';
import 'package:btk_field_app/data/services/pdf_map.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final png = File('web/favicon.png').readAsBytesSync();
  Future<Uint8List> okTile(int z, int x, int y) async => png;
  int imagesIn(List<int> pdf) => RegExp(r'/SMask').allMatches(latin1.decode(pdf)).length;

  BtkRecord located(String id, double lat, double lon) => BtkRecord(id: id, date: DateTime(2026))
    ..latitude = lat
    ..longitude = lon;

  group('tilesAround', () {
    test('the tiles cover the whole map, with the point at its centre', () {
      final tiles = tilesAround(42.3, 45.6)!;
      final tile = tiles.first;
      expect(tile.left, lessThanOrEqualTo(0));
      expect(tile.top, lessThanOrEqualTo(0));
      expect(tiles.map((t) => t.left + 256).reduce((a, b) => a > b ? a : b),
          greaterThanOrEqualTo(pdfMapWidth));
      expect(tiles.map((t) => t.top + 256).reduce((a, b) => a > b ? a : b),
          greaterThanOrEqualTo(pdfMapHeight));
      expect(tiles.length, lessThanOrEqualTo(9));
    });

    test('a known place lands on its known tile', () {
      // Tbilisi, worked out separately with the standard slippy map formula.
      final tiles = tilesAround(41.7151, 44.8271)!;
      final xs = tiles.map((t) => t.x);
      final ys = tiles.map((t) => t.y);
      expect(xs.contains(10232), isTrue);
      expect(ys.contains(6099), isTrue);
    });

    test('across the date line the tiles wrap', () {
      final tiles = tilesAround(0, 179.999)!;
      expect(tiles.map((t) => t.x), contains(0));
      expect(tiles.every((t) => t.x >= 0 && t.x < 1 << 14), isTrue);
    });

    test('near the poles there is no map', () {
      expect(tilesAround(89, 10), isNull);
    });
  });

  group('PdfMapLoader', () {
    test('after a failure it asks no more, so offline stays quick', () async {
      var calls = 0;
      final loader = PdfMapLoader(fetch: (z, x, y) async {
        calls++;
        throw const SocketException('no network');
      });
      expect(await loader.load(42, 45), isNull);
      final after = calls;
      expect(await loader.load(43, 46), isNull);
      expect(calls, after);
    });

    test('one missing tile means no map rather than a map with a hole', () async {
      var calls = 0;
      final loader = PdfMapLoader(fetch: (z, x, y) async {
        if (++calls == 2) throw Exception('404');
        return png;
      });
      expect(await loader.load(42, 45), isNull);
    });

    test('something other than an image is not used', () async {
      final loader = PdfMapLoader(fetch: (z, x, y) async => Uint8List.fromList(utf8.encode('<html>blocked</html>')));
      expect(await loader.load(42, 45), isNull);
    });

    test('nearby records share tiles, and the limit stops the requests', () async {
      var calls = 0;
      final loader = PdfMapLoader(fetch: (z, x, y) async {
        calls++;
        return png;
      });
      await loader.load(42, 45);
      final first = calls;
      await loader.load(42, 45);
      expect(calls, first);

      for (var i = 1; i < 100; i++) {
        await loader.load(42, 45.0 + i);
      }
      expect(calls, lessThanOrEqualTo(pdfMapTileLimit));
    });
  });

  group('PDF', () {
    test('a located record prints its map', () async {
      final pdf = await ExportService.buildPdf([located('A', 42, 45)], fetchTile: okTile);
      expect(imagesIn(pdf), greaterThan(0));
      expect(pdf.length, greaterThan(1000));
    });

    test('offline it is still made, without a map', () async {
      final pdf = await ExportService.buildPdf([located('A', 42, 45)],
          fetchTile: (z, x, y) async => throw const SocketException('no network'));
      expect(latin1.decode(pdf.sublist(0, 4)), '%PDF');
      expect(imagesIn(pdf), 0);
    });

    test('a record with half a coordinate asks for no map', () async {
      var calls = 0;
      final r = BtkRecord(id: 'B', date: DateTime(2026))..latitude = 42;
      await ExportService.buildPdf([r], fetchTile: (z, x, y) async {
        calls++;
        return png;
      });
      expect(calls, 0);
    });
  });
}
