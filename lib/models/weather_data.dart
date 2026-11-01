import '../l10n/generated/app_localizations.dart';

/// Parsed data from api.met.no locationforecast/2.0/compact
class WeatherHour {
  final DateTime time;
  final double temperature; // °C
  final double windSpeed;   // m/s
  final double windDir;     // degrees from north
  final double humidity;    // %
  final double precipitation; // mm
  final String symbolCode;

  const WeatherHour({
    required this.time,
    required this.temperature,
    required this.windSpeed,
    required this.windDir,
    required this.humidity,
    required this.precipitation,
    required this.symbolCode,
  });

  String get emoji => WeatherData.symbolEmoji(symbolCode);

  String windDirLabel(AppLocalizations l10n) {
    final dirs = [
      l10n.windN, l10n.windNE, l10n.windE, l10n.windSE,
      l10n.windS, l10n.windSW, l10n.windW, l10n.windNW,
    ];
    final idx = ((windDir + 22.5) / 45).floor() % 8;
    return dirs[idx];
  }
}

/// One-day summary for the multi-day forecast strip.
class WeatherDay {
  final DateTime date;        // local midnight
  final double minTemp;
  final double maxTemp;
  final String symbolCode;    // representative symbol (≈ noon)
  final double totalPrecip;   // mm

  const WeatherDay({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.symbolCode,
    required this.totalPrecip,
  });

  String get emoji => WeatherData.symbolEmoji(symbolCode);

  bool get isToday {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Localized short day name (or today / tomorrow).
  String dayName(AppLocalizations l10n) {
    if (isToday) return l10n.today;
    if (isTomorrow) return l10n.tomorrow;
    final names = [
      l10n.daySun, l10n.dayMon, l10n.dayTue, l10n.dayWed,
      l10n.dayThu, l10n.dayFri, l10n.daySat,
    ];
    return names[date.weekday % 7];
  }

  factory WeatherDay.fromHours(DateTime date, List<WeatherHour> hours) {
    if (hours.isEmpty) {
      return WeatherDay(
          date: date,
          minTemp: 0,
          maxTemp: 0,
          symbolCode: 'cloudy',
          totalPrecip: 0);
    }
    final temps = hours.map((h) => h.temperature).toList()..sort();
    final precip =
        hours.fold<double>(0, (sum, h) => sum + h.precipitation);

    // Pick symbol from the entry closest to 12:00 local time
    WeatherHour? noonEntry;
    int minDiff = 999;
    for (final h in hours) {
      final local = h.time.toLocal();
      final diff = (local.hour - 12).abs();
      if (diff < minDiff) {
        minDiff = diff;
        noonEntry = h;
      }
    }

    return WeatherDay(
      date: date,
      minTemp: temps.first,
      maxTemp: temps.last,
      symbolCode: noonEntry?.symbolCode ?? hours.first.symbolCode,
      totalPrecip: precip,
    );
  }
}

class WeatherData {
  final WeatherHour current;
  final List<WeatherHour> hourly; // next ~24 h
  final List<WeatherDay> daily;   // next ~7 days (from tomorrow onward)
  final DateTime fetchedAt;

  const WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
    required this.fetchedAt,
  });

  // ── Factory ────────────────────────────────────────────────────────────────

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final timeseries = json['properties']['timeseries'] as List;
    final now = DateTime.now().toUtc();

    // Collect ALL future hours (no 25-limit) for daily grouping
    final allHours = <WeatherHour>[];

    for (final item in timeseries) {
      final time = DateTime.parse(item['time'] as String);
      if (time.isBefore(now.subtract(const Duration(hours: 1)))) continue;

      final details =
          (item['data']['instant']['details'] as Map<String, dynamic>);
      final next1 = item['data']['next_1_hours'] as Map<String, dynamic>?;
      final next6 = item['data']['next_6_hours'] as Map<String, dynamic>?;

      final symbol = (next1?['summary']?['symbol_code'] ??
              next6?['summary']?['symbol_code'] ??
              'cloudy') as String;
      final precip = ((next1?['details']?['precipitation_amount'] ??
              next6?['details']?['precipitation_amount'] ??
              0) as num)
          .toDouble();

      allHours.add(WeatherHour(
        time: time,
        temperature: (details['air_temperature'] as num).toDouble(),
        windSpeed: (details['wind_speed'] as num).toDouble(),
        windDir: (details['wind_from_direction'] as num?)?.toDouble() ?? 0,
        humidity: (details['relative_humidity'] as num?)?.toDouble() ?? 0,
        precipitation: precip,
        symbolCode: symbol,
      ));
    }

    if (allHours.isEmpty) throw const FormatException('Empty timeseries');

    // ── Hourly strip (first 13 entries = current + 12 h) ───────────────────
    final hourly = allHours.skip(1).take(12).toList();

    // ── Daily grouping ──────────────────────────────────────────────────────
    final dayMap = <String, List<WeatherHour>>{};
    for (final h in allHours) {
      final local = h.time.toLocal();
      // Key = "YYYY-MM-DD" in local timezone
      final key =
          '${local.year.toString().padLeft(4, '0')}-'
          '${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')}';
      dayMap.putIfAbsent(key, () => []).add(h);
    }

    // Skip today (already shown as current + hourly strip)
    final todayLocal = DateTime.now();
    final todayKey =
        '${todayLocal.year.toString().padLeft(4, '0')}-'
        '${todayLocal.month.toString().padLeft(2, '0')}-'
        '${todayLocal.day.toString().padLeft(2, '0')}';

    final daily = dayMap.entries
        .where((e) => e.key != todayKey)
        .take(7)
        .map((e) {
          final parts = e.key.split('-');
          final date = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          return WeatherDay.fromHours(date, e.value);
        })
        .toList();

    return WeatherData(
      current: allHours.first,
      hourly: hourly,
      daily: daily,
      fetchedAt: DateTime.now(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String symbolEmoji(String code) {
    final c = code.toLowerCase();
    if (c.contains('thunder')) return '⛈️';
    if (c.contains('heavyrain') || c.contains('heavy_rain')) return '🌧️';
    if (c.contains('lightrain') || c.contains('drizzle')) return '🌦️';
    if (c.contains('rain') || c.contains('shower')) return '🌧️';
    if (c.contains('sleet')) return '🌨️';
    if (c.contains('snow')) return '❄️';
    if (c.contains('fog')) return '🌫️';
    if (c.contains('clearsky') || c.contains('fair')) {
      return c.contains('night') ? '🌙' : '☀️';
    }
    if (c.contains('partlycloudy') || c.contains('partly')) return '⛅';
    if (c.contains('cloud') || c.contains('overcast')) return '☁️';
    return '🌡️';
  }

  static String symbolLabel(String code, AppLocalizations l10n) {
    final c = code.toLowerCase();
    if (c.contains('thunder')) return l10n.wxThunder;
    if (c.contains('heavyrain')) return l10n.wxHeavyRain;
    if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) {
      return l10n.wxRain;
    }
    if (c.contains('sleet')) return l10n.wxSleet;
    if (c.contains('snow')) return l10n.wxSnow;
    if (c.contains('fog')) return l10n.wxFog;
    if (c.contains('clearsky')) return l10n.wxClear;
    if (c.contains('fair')) return l10n.wxFair;
    if (c.contains('partlycloudy') || c.contains('partly')) {
      return l10n.wxPartlyCloudy;
    }
    if (c.contains('overcast')) return l10n.wxOvercast;
    if (c.contains('cloud')) return l10n.wxCloudy;
    return l10n.wxUnknown;
  }
}
