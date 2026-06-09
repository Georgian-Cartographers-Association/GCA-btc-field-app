import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/weather_data.dart';
import '../../../../services/weather_service.dart';

/// Bottom sheet that shows yr.no weather for the given coordinates.
class WeatherPanel extends StatefulWidget {
  final double lat;
  final double lon;

  const WeatherPanel({super.key, required this.lat, required this.lon});

  @override
  State<WeatherPanel> createState() => _WeatherPanelState();
}

class _WeatherPanelState extends State<WeatherPanel> {
  WeatherData? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await WeatherService.fetch(widget.lat, widget.lon);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title row
              Row(
                children: [
                  Icon(Icons.cloud_outlined,
                      color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('ამინდის პროგნოზი',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                    '${widget.lat.toStringAsFixed(3)}°, '
                    '${widget.lon.toStringAsFixed(3)}°',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () {
                      WeatherService.clearCache();
                      _fetch();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_loading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator()))
              else if (_error != null)
                _ErrorView(onRetry: _fetch)
              else if (_data != null)
                _WeatherContent(data: _data!),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Current conditions + 24h forecast ──────────────────────────────────────

class _WeatherContent extends StatelessWidget {
  final WeatherData data;
  const _WeatherContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final cur = data.current;
    final colorScheme = Theme.of(context).colorScheme;
    final tempColor = cur.temperature > 0 ? Colors.deepOrange : Colors.blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Current ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Emoji + description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cur.emoji,
                      style: const TextStyle(fontSize: 52, height: 1.1)),
                  const SizedBox(height: 4),
                  Text(
                    WeatherData.symbolGeorgian(cur.symbolCode),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              // Temperature
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${cur.temperature.round()}°C',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tempColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Wind
                  _InfoRow(Icons.air,
                      '${cur.windSpeed.toStringAsFixed(1)} მ/წ  ${cur.windDirLabel}'),
                  const SizedBox(height: 4),
                  // Humidity
                  _InfoRow(Icons.water_drop_outlined,
                      '${cur.humidity.round()}%'),
                  if (cur.precipitation > 0) ...[
                    const SizedBox(height: 4),
                    _InfoRow(Icons.umbrella_outlined,
                        '${cur.precipitation.toStringAsFixed(1)} მმ'),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── 24h forecast strip ──────────────────────────────────────────────
        Text('24 საათის პროგნოზი',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8)),
        const SizedBox(height: 8),

        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data.hourly.take(12).length,
            separatorBuilder: (context, index) => const SizedBox(width: 4),
            itemBuilder: (ctx, i) {
              final h = data.hourly[i];
              final isNow = i == 0;
              return _ForecastTile(
                hour: h,
                highlight: isNow,
                colorScheme: colorScheme,
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // ── Multi-day forecast ──────────────────────────────────────────────
        if (data.daily.isNotEmpty) ...[
          Text('მომდევნო დღეები',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          ...data.daily.map((day) => _DailyRow(day: day)),
          const SizedBox(height: 8),
        ],

        // ── Attribution ─────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('ამინდი: ',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'yr.no / MET Norway',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade700)),
        ],
      );
}

class _ForecastTile extends StatelessWidget {
  final WeatherHour hour;
  final bool highlight;
  final ColorScheme colorScheme;

  const _ForecastTile({
    required this.hour,
    required this.highlight,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final localTime = hour.time.toLocal();
    final timeStr = DateFormat('HH:mm').format(localTime);
    final tempColor =
        hour.temperature > 0 ? Colors.deepOrange.shade400 : Colors.blue.shade400;

    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: highlight
            ? colorScheme.primaryContainer.withValues(alpha: 0.6)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: highlight
            ? Border.all(color: colorScheme.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(timeStr,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          Text(hour.emoji, style: const TextStyle(fontSize: 20)),
          Text('${hour.temperature.round()}°',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: tempColor)),
          if (hour.precipitation > 0)
            Text('${hour.precipitation.toStringAsFixed(1)}მმ',
                style: const TextStyle(fontSize: 9, color: Colors.blue))
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ── Daily row widget ────────────────────────────────────────────────────────

class _DailyRow extends StatelessWidget {
  final WeatherDay day;
  const _DailyRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasRain = day.totalPrecip > 0.2;
    final isHighlighted =
        day.dayName == 'ხვალ' || day.dayName == 'დღეს';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Day name
          SizedBox(
            width: 48,
            child: Text(
              day.dayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // Emoji
          Text(day.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          // Description (short)
          Expanded(
            child: Text(
              WeatherData.symbolGeorgian(day.symbolCode),
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Rain amount (if any)
          if (hasRain) ...[
            const Icon(Icons.water_drop_outlined, size: 13, color: Colors.blue),
            const SizedBox(width: 2),
            Text(
              '${day.totalPrecip.toStringAsFixed(0)}მმ',
              style: const TextStyle(fontSize: 11, color: Colors.blue),
            ),
            const SizedBox(width: 8),
          ],
          // Min / Max
          Text(
            '${day.minTemp.round()}°',
            style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade400,
                fontWeight: FontWeight.w600),
          ),
          const Text(' / ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            '${day.maxTemp.round()}°',
            style: TextStyle(
                fontSize: 13,
                color: Colors.deepOrange.shade400,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('ამინდის ჩამოტვირთვა ვერ მოხდა',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('შეამოწმეთ ინტერნეტ კავშირი',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('კვლავ ცდა'),
            ),
          ],
        ),
      );
}
