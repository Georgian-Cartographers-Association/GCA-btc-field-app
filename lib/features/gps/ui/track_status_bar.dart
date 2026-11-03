import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/gps_track_extensions.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/gps_track_provider.dart';

/// Green up to 10 m, amber up to 30 m, red beyond.
Color accuracyColor(double metres) => metres <= 10
    ? Colors.green.shade700
    : metres <= 30
        ? const Color(0xFFB26A00)
        : Colors.red.shade700;

/// What recording is doing right now. Empty when nothing is being recorded.
class TrackStatusBar extends ConsumerWidget {
  const TrackStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final track = ref.watch(gpsTrackProvider);
    if (track == null || track.endedAt != null) return const SizedBox.shrink();
    final status = ref.watch(gpsStatusProvider);

    final String text;
    final Color color;
    switch (status.signal) {
      case GpsSignal.waiting:
        text = l10n.gpsWaitingFix;
        color = const Color(0xFFB26A00);
      case GpsSignal.lost:
        text = l10n.gpsSignalLost;
        color = Colors.red.shade700;
      case GpsSignal.ok:
        final acc = status.accuracy;
        text = [
          track.formattedDistance(l10n),
          l10n.trackPointsCount(track.points.length),
          if (acc != null) l10n.accuracyValue(acc.round()),
        ].join(' · ');
        color = acc == null ? Colors.green.shade700 : accuracyColor(acc);
    }

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record, size: 12, color: color),
            const SizedBox(width: 6),
            Flexible(child: Text(text, style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }
}
