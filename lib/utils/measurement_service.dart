import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'utm_service.dart';
import '../l10n/generated/app_localizations.dart';

enum MeasureMode { none, coordinate, line, polygon }

class MeasurementService {
  MeasurementService._();

  static double _seg(UtmCoord a, UtmCoord b) {
    final dx = b.easting - a.easting;
    final dy = b.northing - a.northing;
    return math.sqrt(dx * dx + dy * dy);
  }

  static double totalLength(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    double s = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      s += _seg(
        UtmService.toUtm38N(pts[i].latitude, pts[i].longitude),
        UtmService.toUtm38N(pts[i + 1].latitude, pts[i + 1].longitude),
      );
    }
    return s;
  }

  static double polygonArea(List<LatLng> pts) {
    if (pts.length < 3) return 0;
    final u = pts.map((p) => UtmService.toUtm38N(p.latitude, p.longitude)).toList();
    double area = 0;
    for (int i = 0; i < u.length; i++) {
      final j = (i + 1) % u.length;
      area += u[i].easting * u[j].northing;
      area -= u[j].easting * u[i].northing;
    }
    return area.abs() / 2.0;
  }

  static double polygonPerimeter(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    return totalLength([...pts, pts.first]);
  }

  static String formatLength(double m, AppLocalizations l10n) {
    if (m >= 1000) return '${_n(m / 1000, 3)} ${l10n.unitKm}';
    return '${_n(m, 1)} ${l10n.unitM}';
  }

  static String formatArea(double m2, AppLocalizations l10n) {
    if (m2 >= 1000000) return '${_n(m2 / 1000000, 4)} ${l10n.unitKm2}';
    if (m2 >= 10000) {
      return '${_n(m2 / 10000, 2)} ${l10n.unitHa}  (${_fmtM2(m2, l10n)})';
    }
    return _fmtM2(m2, l10n);
  }

  static String _fmtM2(double m2, AppLocalizations l10n) =>
      '${_n(m2, 1)} ${l10n.unitM2}';

  static String formatWgs84(double lat, double lon) =>
      '${lat.toStringAsFixed(6)}°${lat >= 0 ? "N" : "S"}   '
      '${lon.abs().toStringAsFixed(6)}°${lon >= 0 ? "E" : "W"}';

  static String _n(double v, int d) {
    final s = v.toStringAsFixed(d);
    final p = s.split('.');
    final buf = StringBuffer();
    for (int i = 0; i < p[0].length; i++) {
      if (i > 0 && (p[0].length - i) % 3 == 0) buf.write(' ');
      buf.write(p[0][i]);
    }
    return p.length > 1 ? '${buf.toString()}.${p[1]}' : buf.toString();
  }
}
