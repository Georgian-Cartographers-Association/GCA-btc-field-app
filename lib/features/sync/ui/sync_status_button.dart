import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/sync/sync_status.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../form/ui/widgets/record_tools.dart' show editedStamp;
import '../../records/domain/btk_provider.dart';
import '../domain/kept_versions_provider.dart';
import 'kept_versions_screen.dart';

/// Shows whether shared records have reached the server. Local mode has none.
class SyncStatusButton extends ConsumerWidget {
  const SyncStatusButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(syncScopeProvider) == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final (icon, label) = _describe(ref.watch(syncStatusProvider).valueOrNull, l10n);
    return IconButton(
      icon: Icon(icon),
      tooltip: label,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _SyncStatusSheet(),
      ),
    );
  }
}

// Before the first report nothing is known, which mustn't read as synced.
(IconData, String) _describe(SyncStatus? status, AppLocalizations l10n) {
  if (status == null) return (Icons.cloud_queue, l10n.syncStateChecking);
  if (status.offline) return (Icons.cloud_off, l10n.syncStateOffline);
  if (status.hasPending) return (Icons.cloud_upload_outlined, l10n.syncStateSending);
  return (Icons.cloud_done_outlined, l10n.syncStateSynced);
}

class _SyncStatusSheet extends ConsumerWidget {
  const _SyncStatusSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final known = ref.watch(syncStatusProvider).valueOrNull;
    final status = known ?? const SyncStatus();
    final kept = ref.watch(keptVersionsProvider).valueOrNull?.length ?? 0;
    final (icon, label) = _describe(known, l10n);
    final waiting = [
      for (final r in ref.watch(btkProvider))
        if (status.pendingIds.contains(r.id)) r,
    ];
    final lastSynced = status.lastSynced;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              subtitle: Text(lastSynced == null
                  ? l10n.syncNeverSynced
                  : l10n.syncLastSynced(editedStamp(lastSynced))),
            ),
            if (status.offline)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(l10n.syncOfflineNote),
              ),
            if (status.hasPending)
              ListTile(
                dense: true,
                title: Text(l10n.syncWaitingRecords(waiting.length)),
              ),
            for (final r in waiting)
              ListTile(
                dense: true,
                leading: const Icon(Icons.schedule, size: 18),
                title: Text(r.name.isNotEmpty ? r.name : l10n.btkNumber(r.id)),
              ),
            if (kept > 0)
              ListTile(
                leading: const Icon(Icons.call_split),
                title: Text(l10n.syncKeptBanner(kept)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const KeptVersionsScreen(),
                  ));
                },
              ),
          ],
        ),
      ),
    );
  }
}
