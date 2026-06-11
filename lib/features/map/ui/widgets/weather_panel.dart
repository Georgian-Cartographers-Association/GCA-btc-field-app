import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/weather_data.dart';
import '../../../../data/services/weather_service.dart';

/// Centered dialog that shows yr.no weather for the given coordinates.
/// Opened via [showWeatherDialog] — NOT a bottom sheet.
void showWeatherDialog(BuildContext context, double lat, double lon) {
  showDialog(
    context: context,
    barrierColor: Colors.black38,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.fromLTRB(16, 72, 16, 96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: WeatherPanel(lat: lat, lon: lon),
    ),
  );
}

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await WeatherService.fetch(widget.lat, widget.lon);
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ────────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.cloud_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ამინდის პროგნოზი',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${widget.lat.toStringAsFixed(2)}°, ${widget.lon.toStringAsFixed(2)}°',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'განახლება',
                  onPressed: () {
                    WeatherService.clearCache();
                    _fetch();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Body — accordion-animated ─────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _loading
                  ? const _AccordionLoader()
                  : _error != null
                      ? _ErrorView(onRetry: _fetch)
                      : _data != null
                          ? _WeatherContent(data: _data!)
                          : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Accordion loader ──────────────────────────────────────────────────────────
// Expands from a compact skeleton to full height as it animates in.

class _AccordionLoader extends StatefulWidget {
  const _AccordionLoader();

  @override
  State<_AccordionLoader> createState() => _AccordionLoaderState();
}

class _AccordionLoaderState extends State<_AccordionLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return FadeTransition(
      opacity: _fade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SkeletonBar(height: 80, color: base),
          const SizedBox(height: 12),
          _SkeletonBar(height: 16, width: 140, color: base),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: Row(
              children: List.generate(
                5,
                (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _SkeletonBar(height: 90, color: base),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SkeletonBar(height: 16, width: 120, color: base),
          const SizedBox(height: 8),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SkeletonBar(height: 44, color: base),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double height;
  final double? width;
  final Color color;

  const _SkeletonBar({required this.height, this.width, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      );
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 52, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'ამინდის ჩამოტვირთვა ვერ მოხდა',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'შეამოწმეთ ინტერნეტ კავშირი',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('კვლავ ცდა'),
              ),
            ],
          ),
        ),
      );
}

// ── Weather content ───────────────────────────────────────────────────────────

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
                  _InfoRow(Icons.air,
                      '${cur.windSpeed.toStringAsFixed(1)} მ/წ  ${cur.windDirLabel}'),
                  const SizedBox(height: 4),
                  _InfoRow(Icons.water_drop_outlined, '${cur.humidity.round()}%'),
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

        // ── 24h forecast ────────────────────────────────────────────────────
        _SectionLabel('24 საათის პროგნოზი', colorScheme),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data.hourly.take(12).length,
            separatorBuilder: (_, _) => const SizedBox(width: 4),
            itemBuilder: (ctx, i) => _ForecastTile(
              hour: data.hourly[i],
              highlight: i == 0,
              colorScheme: colorScheme,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Multi-day ────────────────────────────────────────────────────────
        if (data.daily.isNotEmpty) ...[
          _SectionLabel('მომდევნო დღეები', colorScheme),
          const SizedBox(height: 8),
          ...data.daily.map((day) => _DailyRow(day: day)),
          const SizedBox(height: 8),
        ],

        // ── Attribution ──────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('ამინდი: ',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
            const Text(
              'yr.no / MET Norway',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                  decoration: TextDecoration.underline),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;
  const _SectionLabel(this.text, this.colorScheme);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      );
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
    final timeStr = DateFormat('HH:mm').format(hour.time.toLocal());
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
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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

class _DailyRow extends StatelessWidget {
  final WeatherDay day;
  const _DailyRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHighlighted = day.dayName == 'ხვალ' || day.dayName == 'დღეს';
    final hasRain = day.totalPrecip > 0.2;

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
          SizedBox(
            width: 48,
            child: Text(
              day.dayName,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isHighlighted ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Text(day.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              WeatherData.symbolGeorgian(day.symbolCode),
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasRain) ...[
            const Icon(Icons.water_drop_outlined, size: 13, color: Colors.blue),
            const SizedBox(width: 2),
            Text('${day.totalPrecip.toStringAsFixed(0)}მმ',
                style: const TextStyle(fontSize: 11, color: Colors.blue)),
            const SizedBox(width: 8),
          ],
          Text('${day.minTemp.round()}°',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade400,
                  fontWeight: FontWeight.w600)),
          const Text(' / ',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text('${day.maxTemp.round()}°',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.deepOrange.shade400,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
