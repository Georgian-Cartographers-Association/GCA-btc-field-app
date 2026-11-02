import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:btk_field_app/database/btk_database.dart';
import 'package:btk_field_app/features/gps/domain/gps_track_provider.dart';
import 'package:btk_field_app/features/gps/domain/location_settings.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:btk_field_app/models/gps_track.dart';
import 'package:btk_field_app/models/record_quality.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Position _pos(double lat, {double accuracy = 5, double altitude = 500}) => Position(
      latitude: lat,
      longitude: 43,
      timestamp: DateTime(2026, 1, 1, 12),
      accuracy: accuracy,
      altitude: altitude,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

const _settings = LocationSettings();

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Directory dir;
  late List<GpsStatus> statuses;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('gps_test');
    await BtkDatabase.openAt(p.join(dir.path, 'test.db'));
    statuses = [];
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  GpsTrackNotifier notifier(List<StreamController<Position>> streams,
          {Duration retryAfter = const Duration(milliseconds: 5)}) =>
      GpsTrackNotifier(
        statuses.add,
        positions: (_) {
          final c = StreamController<Position>();
          streams.add(c);
          return c.stream;
        },
        retryAfter: retryAfter,
      );

  group('recording', () {
    test('points are in the database before the track is finished', () async {
      final streams = <StreamController<Position>>[];
      final n = notifier(streams);
      await n.startTracking(_settings);
      streams.single.add(_pos(42.1));
      streams.single.add(_pos(42.2, accuracy: 7));
      await _settle();

      final stored = (await BtkDatabase.getUnfinishedTracks()).single;
      expect(stored.points.map((p) => p.lat), [42.1, 42.2]);
      expect(stored.points.last.accuracy, 7);
      expect(statuses.last.signal, GpsSignal.ok);
      expect(statuses.last.accuracy, 7);
      n.dispose();
    });

    test('finishing moves points into the track, in the old format', () async {
      final streams = <StreamController<Position>>[];
      final n = notifier(streams);
      await n.startTracking(_settings);
      streams.single.add(_pos(42.1));
      streams.single.add(_pos(42.2));
      await _settle();

      final finished = await n.stopTracking();

      expect(finished!.points, hasLength(2));
      final db = await BtkDatabase.database;
      expect(await db.query('gps_track_points'), isEmpty);
      final row = (await db.query('gps_tracks')).single;
      expect(row['ended_at'], isNotNull);
      final json = jsonDecode(row['points_json'] as String) as List;
      expect(json.map((e) => e['lat']), [42.1, 42.2]);
      expect(await BtkDatabase.getUnfinishedTracks(), isEmpty);
      n.dispose();
    });

    test('an error keeps the track and reconnects to the same track', () async {
      final streams = <StreamController<Position>>[];
      final n = notifier(streams);
      await n.startTracking(_settings);
      streams.first.add(_pos(42.1));
      await _settle();

      streams.first.addError(const LocationServiceDisabledException());
      await Future<void>.delayed(Duration.zero);
      expect(statuses.last.signal, GpsSignal.lost);
      expect(n.isTracking, isTrue);
      expect(n.state!.points, hasLength(1));

      await _settle();
      expect(streams, hasLength(2), reason: 'it subscribes again');
      streams.last.add(_pos(42.2));
      await _settle();

      expect(statuses.last.signal, GpsSignal.ok);
      final finished = await n.stopTracking();
      expect(finished!.points.map((p) => p.lat), [42.1, 42.2]);
      n.dispose();
    });

    test('a stream that ends also counts as lost', () async {
      final streams = <StreamController<Position>>[];
      final n = notifier(streams, retryAfter: const Duration(hours: 1));
      await n.startTracking(_settings);
      await streams.first.close();
      await _settle();
      expect(statuses.last.signal, GpsSignal.lost);
      expect(n.isTracking, isTrue);
      n.dispose();
    });

    test('no reconnect after stopping', () async {
      final streams = <StreamController<Position>>[];
      final n = notifier(streams);
      await n.startTracking(_settings);
      streams.first.addError(StateError('x'));
      await Future<void>.delayed(Duration.zero);
      await n.stopTracking();
      await _settle();
      expect(streams, hasLength(1));
      n.dispose();
    });

    test('a failed start leaves nothing recording', () async {
      await (await BtkDatabase.database).close();
      final streams = <StreamController<Position>>[];
      final n = notifier(streams);
      await expectLater(n.startTracking(_settings), throwsA(anything));
      expect(n.isTracking, isFalse);
      expect(streams, isEmpty);
      n.dispose();
    });
  });

  group('after a crash', () {
    test('an interrupted track keeps its points and can go on', () async {
      final streams = <StreamController<Position>>[];
      final crashed = notifier(streams);
      await crashed.startTracking(_settings);
      streams.single.add(_pos(42.1));
      await _settle();
      crashed.dispose(); // the process is gone, and nothing was finished

      final interrupted = (await BtkDatabase.getUnfinishedTracks()).single;
      expect(interrupted.points, hasLength(1));

      final after = <StreamController<Position>>[];
      final n = notifier(after);
      n.resume(interrupted, _settings);
      after.single.add(_pos(42.2));
      await _settle();
      final finished = await n.stopTracking();

      expect(finished!.id, interrupted.id);
      expect(finished.points.map((p) => p.lat), [42.1, 42.2]);
      final stored = (await BtkDatabase.getAllTracks()).single;
      expect(stored.points.map((p) => p.lat), [42.1, 42.2]);
      n.dispose();
    });

    test('a track from an older version keeps points already in its JSON', () async {
      final old = GpsTrack(id: 'OLD', startedAt: DateTime(2026), points: [
        GpsPoint(lat: 1, lon: 2, altitude: 3, time: DateTime(2026)),
      ]);
      await BtkDatabase.insertTrack(old);
      await BtkDatabase.appendTrackPoints('OLD', [
        GpsPoint(lat: 4, lon: 5, altitude: 6, time: DateTime(2026, 2)),
      ]);

      expect((await BtkDatabase.getAllTracks()).single.points.map((p) => p.lat), [1, 4]);

      await BtkDatabase.finishTrack('OLD', DateTime(2026, 3));
      final t = (await BtkDatabase.getAllTracks()).single;
      expect(t.points.map((p) => p.lat), [1, 4]);
      expect(t.endedAt, DateTime(2026, 3));
    });
  });

  group('damaged data', () {
    test('a damaged track is counted, kept, and hides nothing', () async {
      await BtkDatabase.insertTrack(GpsTrack(id: 'GOOD', startedAt: DateTime(2026)));
      final db = await BtkDatabase.database;
      await db.insert('gps_tracks', {
        'id': 'BAD',
        'started_at': '2026-02-01',
        'points_json': 'not json',
      });

      final r = await BtkDatabase.readAllTracks();

      expect(r.tracks.map((t) => t.id), ['GOOD']);
      expect(r.skipped, 1);
      expect(await db.query('gps_tracks'), hasLength(2));
    });

    test('a damaged point costs only that point', () {
      final t = GpsTrack.fromMap({
        'id': 'A',
        'started_at': '2026-01-01',
        'ended_at': null,
        'points_json':
            '[{"lat":1,"lon":2,"alt":3,"time":"2026-01-01"},{"lat":"x"},{"lat":4,"lon":5,"time":"2026-01-02"}]',
      });
      expect(t.points.map((p) => p.lat), [1, 4]);
    });

    test('finishing refuses to overwrite unreadable points', () async {
      final db = await BtkDatabase.database;
      await db.insert('gps_tracks', {
        'id': 'BAD',
        'started_at': '2026-02-01',
        'points_json': 'not json',
      });
      await expectLater(BtkDatabase.finishTrack('BAD', DateTime(2026)), throwsA(anything));
      final row = (await db.query('gps_tracks')).single;
      expect(row['points_json'], 'not json');
      expect(row['ended_at'], isNull);
    });
  });

  test('deleting a track removes its pending points', () async {
    await BtkDatabase.insertTrack(GpsTrack(id: 'A', startedAt: DateTime(2026)));
    await BtkDatabase.appendTrackPoints(
        'A', [GpsPoint(lat: 1, lon: 2, altitude: 3, time: DateTime(2026))]);
    await BtkDatabase.deleteTrack('A');
    final db = await BtkDatabase.database;
    expect(await db.query('gps_track_points'), isEmpty);
    expect(await db.query('gps_tracks'), isEmpty);
  });

  test('old point JSON with no accuracy still reads, and stays without it', () {
    final point = GpsPoint.fromJson({'lat': 1, 'lon': 2, 'alt': 3, 'time': '2026-01-01'});
    expect(point.accuracy, isNull);
    expect(point.toJson().containsKey('acc'), isFalse);
  });

  test('nearestTo finds the closest point', () {
    GpsPoint pt(double lat) => GpsPoint(lat: lat, lon: 43, altitude: 0, time: DateTime(2026));
    final t = GpsTrack(id: 'A', startedAt: DateTime(2026), points: [pt(41), pt(42), pt(43)]);
    expect(t.nearestTo(42.2, 43)!.lat, 42);
    expect(GpsTrack(id: 'B', startedAt: DateTime(2026)).nearestTo(1, 1), isNull);
  });

  group('settleFix', () {
    test('takes the latest fix after the settle time', () async {
      final c = StreamController<Position>();
      final fix = settleFix(c.stream, settle: const Duration(milliseconds: 20));
      c.add(_pos(1, altitude: 530));
      c.add(_pos(2, altitude: 500));
      expect((await fix).altitude, 500);
      await c.close();
    });

    test('gives the fix it has if the stream stops', () async {
      final c = StreamController<Position>();
      final fix = settleFix(c.stream);
      c.add(_pos(1));
      await Future<void>.delayed(Duration.zero);
      await c.close();
      expect((await fix).latitude, 1);
    });

    test('fails after the limit with no fix', () async {
      final c = StreamController<Position>();
      await expectLater(
        settleFix(c.stream, limit: const Duration(milliseconds: 10)),
        throwsA(isA<TimeoutException>()),
      );
      await c.close();
    });

    test('survives an error before the first fix', () async {
      final c = StreamController<Position>();
      final fix = settleFix(c.stream, settle: const Duration(milliseconds: 5));
      c.addError(StateError('no signal yet'));
      c.add(_pos(3));
      expect((await fix).latitude, 3);
      await c.close();
    });
  });

  group('record links', () {
    test('new fields stay out of JSON until set, so old output is unchanged', () {
      final j = BtkRecord(id: 'A', date: DateTime(2026)).toJson();
      expect(j.containsKey('coordAccuracy'), isFalse);
      expect(j.containsKey('trackId'), isFalse);
    });

    test('new fields round-trip', () {
      final r = BtkRecord(id: 'A', date: DateTime(2026), coordAccuracy: 8, trackId: 'T1');
      final back = BtkRecord.fromJson(r.toJson());
      expect(back.coordAccuracy, 8);
      expect(back.trackId, 'T1');
    });

    test('low accuracy gets a note', () {
      BtkRecord r(double a) => BtkRecord(
          id: 'A',
          date: DateTime(2026),
          location: 'x',
          latitude: 42,
          longitude: 43,
          coordAccuracy: a);
      expect(r(50).qualityNotes(now: DateTime(2026, 6)), isEmpty);
      expect(r(51).qualityNotes(now: DateTime(2026, 6)), hasLength(1));
    });
  });
}
