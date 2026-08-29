import 'dart:math' as math;

/// Coordinate format conversion utilities.
/// Handles DD, DM, DMS, UTM 37N, UTM 38N.
class CoordConverter {
  CoordConverter._();

  // WGS84 ellipsoid constants
  static const double _a = 6378137.0;
  static const double _f = 1.0 / 298.257223563;
  static const double _k0 = 0.9996;
  static const double _e0 = 500000.0;
  static final double _e2 = 2 * _f - _f * _f;
  static final double _ePrime2 = _e2 / (1.0 - _e2);

  // Georgia WGS84 bounding box
  static const double latMin = 41.00, latMax = 43.70;
  static const double lonMin = 40.00, lonMax = 46.80;

  static bool inGeorgiaBounds(double lat, double lon) =>
      lat >= latMin && lat <= latMax && lon >= lonMin && lon <= lonMax;

  // ─── DD → display strings ──────────────────────────────────────────────────

  static String ddToDms(double dd, {bool isLat = true}) {
    final sign = dd < 0 ? -1 : 1;
    final abs = dd.abs();
    final deg = abs.truncate();
    final minFull = (abs - deg) * 60;
    final min = minFull.truncate();
    final sec = (minFull - min) * 60;
    final hem = isLat ? (sign >= 0 ? 'N' : 'S') : (sign >= 0 ? 'E' : 'W');
    final secStr = sec.toStringAsFixed(2).padLeft(5, '0');
    return "$deg°${min.toString().padLeft(2, '0')}'$secStr\"$hem";
  }

  static String ddToDm(double dd, {bool isLat = true}) {
    final sign = dd < 0 ? -1 : 1;
    final abs = dd.abs();
    final deg = abs.truncate();
    final min = (abs - deg) * 60;
    final hem = isLat ? (sign >= 0 ? 'N' : 'S') : (sign >= 0 ? 'E' : 'W');
    return "$deg°${min.toStringAsFixed(4)}'$hem";
  }

  static String ddToString(double dd, {bool isLat = true}) {
    return dd.toStringAsFixed(6);
  }

  // ─── Parse DMS / DM → DD ──────────────────────────────────────────────────

  static double? dmsToDD(String s) {
    final clean = _normalise(s);
    // deg min sec [hem]
    final re = RegExp(
        r'^(-?)(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)\s*([NSEWnsew]?)$');
    final m = re.firstMatch(clean);
    if (m == null) return null;
    final neg = m.group(1) == '-';
    final deg = double.parse(m.group(2)!);
    final min = double.parse(m.group(3)!);
    final sec = double.parse(m.group(4)!);
    final hem = m.group(5)!.toUpperCase();
    var dd = deg + min / 60.0 + sec / 3600.0;
    if (neg || hem == 'S' || hem == 'W') dd = -dd;
    return dd;
  }

  static double? dmToDD(String s) {
    final clean = _normalise(s);
    // deg min.frac [hem]
    final re = RegExp(
        r'^(-?)(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)\s*([NSEWnsew]?)$');
    final m = re.firstMatch(clean);
    if (m == null) return null;
    final neg = m.group(1) == '-';
    final deg = double.parse(m.group(2)!);
    final min = double.parse(m.group(3)!);
    final hem = m.group(4)!.toUpperCase();
    var dd = deg + min / 60.0;
    if (neg || hem == 'S' || hem == 'W') dd = -dd;
    return dd;
  }

  static String _normalise(String s) => s
      .replaceAll('°', ' ')
      .replaceAll("'", ' ')
      .replaceAll('"', ' ')
      .replaceAll(',', '.')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // ─── Smart parse: DD, DM, or DMS ──────────────────────────────────────────

  static double? parseCoord(String s) {
    final trimmed = s.trim();
    final plain = double.tryParse(trimmed);
    if (plain != null) return plain;
    return dmsToDD(trimmed) ?? dmToDD(trimmed);
  }

  /// True if the string appears to contain a DMS or DM value (not plain DD).
  static bool isNonDecimal(String s) {
    if (s.trim().isEmpty) return false;
    if (double.tryParse(s.trim()) != null) return false;
    return s.contains('°') ||
        s.contains("'") ||
        s.contains('"') ||
        RegExp(r'[NSEWnsew]').hasMatch(s);
  }

  // ─── UTM projection (forward) ─────────────────────────────────────────────

  static UtmResult toUtm37N(double latDeg, double lonDeg) =>
      _toUtm(latDeg, lonDeg, 39.0);

  static UtmResult toUtm38N(double latDeg, double lonDeg) =>
      _toUtm(latDeg, lonDeg, 45.0);

  // ─── UTM → DD (inverse) ───────────────────────────────────────────────────

  /// Converts UTM Zone 37N (cm 39°E) → WGS84 DD.
  static (double lat, double lon) fromUtm37N(double easting, double northing) =>
      _fromUtm(easting, northing, 39.0);

  /// Converts UTM Zone 38N (cm 45°E) → WGS84 DD.
  static (double lat, double lon) fromUtm38N(double easting, double northing) =>
      _fromUtm(easting, northing, 45.0);

  static (double, double) _fromUtm(
      double easting, double northing, double cmDeg) {
    final lon0 = cmDeg * math.pi / 180.0;
    final x = easting - _e0;
    final e4 = _e2 * _e2;
    final e6 = e4 * _e2;
    final M = northing / _k0;
    final mu = M / (_a * (1 - _e2 / 4 - 3 * e4 / 64 - 5 * e6 / 256));
    final e1 = (1 - math.sqrt(1 - _e2)) / (1 + math.sqrt(1 - _e2));
    final e12 = e1 * e1;
    final e13 = e12 * e1;
    final e14 = e13 * e1;
    final phi1 = mu +
        (3 * e1 / 2 - 27 * e13 / 32) * math.sin(2 * mu) +
        (21 * e12 / 16 - 55 * e14 / 32) * math.sin(4 * mu) +
        (151 * e13 / 96) * math.sin(6 * mu) +
        (1097 * e14 / 512) * math.sin(8 * mu);
    final sinPhi1 = math.sin(phi1);
    final cosPhi1 = math.cos(phi1);
    final tanPhi1 = math.tan(phi1);
    final n1 = _a / math.sqrt(1 - _e2 * sinPhi1 * sinPhi1);
    final t1 = tanPhi1 * tanPhi1;
    final c1 = _ePrime2 * cosPhi1 * cosPhi1;
    final r1 = _a *
        (1 - _e2) /
        math.pow(1 - _e2 * sinPhi1 * sinPhi1, 1.5);
    final d = x / (n1 * _k0);
    final d2 = d * d;
    final d3 = d2 * d;
    final d4 = d3 * d;
    final d5 = d4 * d;
    final d6 = d5 * d;
    final latRad = phi1 -
        (n1 * tanPhi1 / r1) *
            (d2 / 2 -
                (5 + 3 * t1 + 10 * c1 - 4 * c1 * c1 - 9 * _ePrime2) *
                    d4 /
                    24 +
                (61 +
                        90 * t1 +
                        298 * c1 +
                        45 * t1 * t1 -
                        252 * _ePrime2 -
                        3 * c1 * c1) *
                    d6 /
                    720);
    final lonRad = lon0 +
        (d -
                (1 + 2 * t1 + c1) * d3 / 6 +
                (5 - 2 * c1 + 28 * t1 - 3 * c1 * c1 + 8 * _ePrime2 +
                        24 * t1 * t1) *
                    d5 /
                    120) /
            cosPhi1;
    return (latRad * 180 / math.pi, lonRad * 180 / math.pi);
  }

  static UtmResult _toUtm(double latDeg, double lonDeg, double cmDeg) {
    final lon0 = cmDeg * math.pi / 180.0;
    final lat = latDeg * math.pi / 180.0;
    final lon = lonDeg * math.pi / 180.0;
    final sinLat = math.sin(lat);
    final cosLat = math.cos(lat);
    final tanLat = math.tan(lat);
    final t = tanLat * tanLat;
    final c = _ePrime2 * cosLat * cosLat;
    final nu = _a / math.sqrt(1.0 - _e2 * sinLat * sinLat);
    final A = cosLat * (lon - lon0);
    final A2 = A * A;
    final A3 = A2 * A;
    final A4 = A3 * A;
    final A5 = A4 * A;
    final A6 = A5 * A;
    final e4 = _e2 * _e2;
    final e6 = e4 * _e2;
    final M = _a *
        ((1 - _e2 / 4 - 3 * e4 / 64 - 5 * e6 / 256) * lat -
            (3 * _e2 / 8 + 3 * e4 / 32 - 45 * e6 / 1024) * math.sin(2 * lat) +
            (15 * e4 / 256 + 45 * e6 / 1024) * math.sin(4 * lat) -
            (35 * e6 / 3072) * math.sin(6 * lat));
    final easting = _k0 *
            nu *
            (A +
                (1 - t + c) * A3 / 6.0 +
                (5 - 18 * t + t * t + 72 * c - 58 * _ePrime2) *
                    A5 /
                    120.0) +
        _e0;
    final northing = _k0 *
        (M +
            nu *
                tanLat *
                (A2 / 2.0 +
                    (5 - t + 9 * c + 4 * c * c) * A4 / 24.0 +
                    (61 - 58 * t + t * t + 600 * c - 330 * _ePrime2) *
                        A6 /
                        720.0));
    return UtmResult(easting: easting, northing: northing);
  }
}

class UtmResult {
  const UtmResult({required this.easting, required this.northing});
  final double easting;
  final double northing;

  String formatted() => 'E ${_fmt(easting)}   N ${_fmt(northing)}';

  static String _fmt(double v) {
    final s = v.toStringAsFixed(1);
    final parts = s.split('.');
    final buf = StringBuffer();
    final intStr = parts[0];
    for (int i = 0; i < intStr.length; i++) {
      if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
      buf.write(intStr[i]);
    }
    return '${buf.toString()}.${parts[1]}';
  }
}
