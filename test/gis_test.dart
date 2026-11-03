import 'dart:convert';
import 'package:btk_field_app/features/map/domain/geojson_parse.dart';
import 'package:btk_field_app/features/records/domain/record_filter.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

BtkRecord _r(String id, {String group = '', DateTime? date, double? lat, double? lon, String location = ''}) =>
    BtkRecord(id: id, date: date ?? DateTime(2026, 6, 15), group: group, latitude: lat, longitude: lon, location: location);

void main() {
  group('filter', () {
    final done = _r('D', group: 'რაჭა', lat: 42, lon: 43, location: 'x');
    final open = _r('O', group: 'კახეთი');
    final none = _r('N', lat: 41, lon: 44, location: 'y');
    final all = [done, open, none];
    List<String> ids(RecordFilter f) => f.apply(all).map((r) => r.id).toList();

    test('off by default, and shows everything', () {
      expect(const RecordFilter().isActive, isFalse);
      expect(ids(const RecordFilter()), ['D', 'O', 'N']);
    });

    test('by group, including no group', () {
      expect(ids(const RecordFilter(groups: {'რაჭა'})), ['D']);
      expect(ids(const RecordFilter(groups: {''})), ['N']);
      expect(ids(const RecordFilter(groups: {'რაჭა', ''})), ['D', 'N']);
    });

    test('unfinished only', () {
      expect(ids(const RecordFilter(unfinishedOnly: true)), ['O']);
    });

    test('the end date counts as a whole day', () {
      final f = RecordFilter(dates: DateTimeRange(start: DateTime(2026, 6, 1), end: DateTime(2026, 6, 15)));
      expect(f.matches(_r('A', date: DateTime(2026, 6, 15, 23, 59))), isTrue);
      expect(f.matches(_r('B', date: DateTime(2026, 6, 16))), isFalse);
      expect(f.matches(_r('C', date: DateTime(2026, 5, 31, 23))), isFalse);
    });

    test('conditions combine', () {
      expect(ids(const RecordFilter(groups: {'კახეთი', 'რაჭა'}, unfinishedOnly: true)), ['O']);
    });

    test('filtering does not change the records', () {
      const RecordFilter(groups: {'რაჭა'}).apply(all);
      expect(all, hasLength(3));
    });
  });

  group('groups', () {
    test('are listed once, sorted, with no empty entry', () {
      final list = groupsIn([_r('A', group: 'ბ'), _r('B', group: ' ა '), _r('C', group: 'ბ'), _r('D')]);
      expect(list, ['ა', 'ბ']);
    });

    test('colour depends only on the name', () {
      expect(groupColor('რაჭა'), groupColor(' რაჭა '));
      expect(groupColor('რაჭა'), isA<Color>());
    });

    test('old JSON has no group, and an empty one stays out of new JSON', () {
      final r = BtkRecord.fromJson({'id': 'A', 'date': '2026-01-01'});
      expect(r.group, '');
      expect(r.toJson().containsKey('group'), isFalse);
      expect(BtkRecord.fromJson(_r('A', group: 'x').toJson()).group, 'x');
    });
  });

  group('places on the map', () {
    test('a record needs two valid coordinates', () {
      expect(_r('A', lat: 42, lon: 43).mapPoint, const LatLng(42, 43));
      expect(_r('A').mapPoint, isNull);
      expect(_r('A', lat: 42).mapPoint, isNull, reason: 'used to crash the map');
      expect(_r('A', lon: 43).mapPoint, isNull);
      expect(_r('A', lat: 95, lon: 43).mapPoint, isNull);
    });

    test('half-entered coordinates stay out of the email text', () {
      expect(_r('A', lat: 42).toEmailText(), isNot(contains('null')));
    });

    test('recordsWithin keeps only records that have a place inside', () {
      final out = recordsWithin(
        [_r('IN', lat: 42, lon: 43), _r('OUT', lat: 10, lon: 43), _r('NONE')],
        contains: (p) => p.latitude > 40,
      );
      expect(out.map((r) => r.id), ['IN']);
    });
  });

  group('GeoJSON parsing', () {
    final raw = jsonEncode({
      'features': [
        {
          'properties': {'NAME': 'A'},
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [[43.0, 42.0], [44.0, 42.0], [44.0, 41.0]]
            ],
          },
        },
        {
          'properties': {'NAME': 'B'},
          'geometry': {
            'type': 'MultiPolygon',
            'coordinates': [
              [[[40.0, 40.0], [41.0, 41.0]]],
              [[[45.0, 43.0], [46.0, 44.0]]],
            ],
          },
        },
        {
          'properties': {'NAME': ''},
          'geometry': {'type': 'Polygon', 'coordinates': [[[1.0, 1.0]]]},
        },
      ],
    });

    test('polygons read as lat, lon', () {
      final polys = parsePolygonsNow(raw);
      expect(polys, hasLength(4));
      expect(polys.first.first, const LatLng(42, 43));
    });

    test('places get bounds over all their parts, and need a name', () {
      final places = parsePlacesNow(raw, 'NAME');
      expect(places.map((p) => p.name), ['A', 'B']);
      final b = places.last;
      expect([b.minLat, b.maxLat, b.minLon, b.maxLon], [40, 44, 40, 46]);
    });

    test('the isolate version gives the same result', () async {
      expect(await parsePolygons(raw), hasLength(4));
      expect((await parsePlaces(raw, 'NAME')), hasLength(2));
    });
  });
}
