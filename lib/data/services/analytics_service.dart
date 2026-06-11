import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper around FirebaseAnalytics.
/// All calls are fire-and-forget and fail silently if Firebase is not
/// configured (placeholder keys) so the app always runs.
class AnalyticsService {
  static FirebaseAnalytics? _instance;

  static FirebaseAnalytics get _a {
    _instance ??= FirebaseAnalytics.instance;
    return _instance!;
  }

  static Future<void> _log(String name,
      [Map<String, Object>? params]) async {
    try {
      await _a.logEvent(name: name, parameters: params);
    } catch (_) {}
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  static Future<void> logScreenView(String screenName) async {
    try {
      await _a.logScreenView(screenName: screenName);
    } catch (_) {}
  }

  // ── BTK Records ────────────────────────────────────────────────────────────

  static Future<void> logRecordCreated() =>
      _log('btk_record_created');

  static Future<void> logRecordSaved() =>
      _log('btk_record_saved');

  static Future<void> logRecordDeleted() =>
      _log('btk_record_deleted');

  static Future<void> logEmailSent(int recipientCount) =>
      _log('btk_email_sent', {'recipients': recipientCount});

  // ── Map ────────────────────────────────────────────────────────────────────

  static Future<void> logGpsDetect() =>
      _log('gps_detect_used');

  static Future<void> logMeasurement(String mode) =>
      _log('measurement_used', {'mode': mode});

  static Future<void> logLayerToggled(String layer, bool enabled) =>
      _log('layer_toggled', {'layer': layer, 'enabled': enabled ? 1 : 0});

  static Future<void> logTileServiceAdded(String type) =>
      _log('tile_service_added', {'type': type});

  // ── Tools ──────────────────────────────────────────────────────────────────

  static Future<void> logWeatherViewed() =>
      _log('weather_viewed');

  static Future<void> logPdfOpened() =>
      _log('pdf_opened');

  static Future<void> logRasterAdded(String source) =>
      _log('raster_added', {'source': source}); // 'asset' | 'device'

  // ── GPS Track ──────────────────────────────────────────────────────────────

  static Future<void> logGpsTrackStarted() =>
      _log('gps_track_started');

  static Future<void> logGpsTrackStopped(int pointCount, double meters) =>
      _log('gps_track_stopped', {
        'point_count': pointCount,
        'distance_m': meters.round(),
      });

  static Future<void> logGpxExported() =>
      _log('gpx_exported');

  // ── Export ─────────────────────────────────────────────────────────────────

  static Future<void> logExport(String format) =>
      _log('records_exported', {'format': format}); // 'csv' | 'geojson' | 'pdf'
}
