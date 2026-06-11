import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/weather_data.dart';

/// Fetches weather forecasts from api.met.no (yr.no).
/// Free, no API key. Requires User-Agent header and caches to avoid abuse.
class WeatherService {
  static const _base =
      'https://api.met.no/weatherapi/locationforecast/2.0/compact';

  // Use app name + contact — required by api.met.no Terms of Service.
  static const _userAgent =
      'BtkFieldApp/1.1 (GCA field survey; github.com/Georgian-Cartographers-Association/GCA-btc-field-app)';

  // In-memory cache: rounded key → (data, fetchTime)
  static final _cache = <String, (WeatherData, DateTime)>{};
  static const _cacheTtl = Duration(minutes: 20);

  /// Fetch weather for [lat]/[lon].
  /// Returns cached result if < 20 min old.
  static Future<WeatherData> fetch(double lat, double lon) async {
    // Round to 2 decimal places (~1 km grid) for cache key
    final key =
        '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';

    final cached = _cache[key];
    if (cached != null &&
        DateTime.now().difference(cached.$2) < _cacheTtl) {
      return cached.$1;
    }

    final uri = Uri.parse(
        '$_base?lat=${lat.toStringAsFixed(4)}&lon=${lon.toStringAsFixed(4)}');

    final response = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('api.met.no ${response.statusCode}');
    }

    final data = WeatherData.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
    _cache[key] = (data, DateTime.now());
    return data;
  }

  static void clearCache() => _cache.clear();
}
