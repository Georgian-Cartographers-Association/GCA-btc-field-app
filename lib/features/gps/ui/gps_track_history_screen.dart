import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/datetime_extensions.dart';
import '../../../core/extensions/gps_track_extensions.dart';
import '../../../database/btk_database.dart';
import '../../../models/gps_track.dart';
import '../../../data/services/export_service.dart';
import '../../../l10n/generated/app_localizations.dart';

final _gpsHistoryProvider = FutureProvider<List<GpsTrack>>((ref) async {
  return BtkDatabase.getAllTracks();
});

class GpsTrackHistoryScreen extends ConsumerWidget {
  const GpsTrackHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tracksAsync = ref.watch(_gpsHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gpsTrackHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () => ref.invalidate(_gpsHistoryProvider),
          ),
        ],
      ),
      body: tracksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('შეცდომა: $e')),
        data: (tracks) => tracks.isEmpty
            ? _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: tracks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _TrackCard(
                  track: tracks[i],
                  onExport: () => ExportService.shareGpx(tracks[i]),
                  onDelete: () async {
                    final ok = await _confirmDelete(context);
                    if (!ok) return;
                    await BtkDatabase.deleteTrack(tracks[i].id);
                    ref.invalidate(_gpsHistoryProvider);
                  },
                ),
              ),
      ),
    );
  }

  static Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.deleteTrackTitle),
            content: Text(l10n.confirmDeleteTrack),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.delete,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.route,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noTracksFound,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.noTracksHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }
}

// ── Track card ────────────────────────────────────────────────────────────────

class _TrackCard extends StatelessWidget {
  final GpsTrack track;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _TrackCard({
    required this.track,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = track.endedAt == null;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.red.withValues(alpha: 0.12)
                    : Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.radio_button_on : Icons.route,
                size: 22,
                color: isActive
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.startedAt.toGeorgianDateString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    _Chip(Icons.straighten, track.formattedDistance),
                    const SizedBox(width: 8),
                    _Chip(Icons.timer_outlined, track.formattedDuration),
                    const SizedBox(width: 8),
                    _Chip(Icons.location_on_outlined,
                        '${track.points.length}'),
                  ]),
                  if (isActive) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.trackRecording,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isActive)
                  IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: l10n.exportGpx,
                    onPressed: onExport,
                    iconSize: 20,
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: l10n.delete,
                  onPressed: onDelete,
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5)),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65)),
          ),
        ],
      );
}
