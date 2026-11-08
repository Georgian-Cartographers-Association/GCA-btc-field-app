import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_messenger.dart';
import '../../../data/sync/conflict_store.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/btk_record.dart';
import '../../records/domain/btk_provider.dart';
import '../../stats/domain/group_analytics.dart' show shortDate;
import '../../stats/ui/compare_screen.dart';
import '../domain/kept_versions_provider.dart';

/// Shows above the records list while kept versions wait for a decision.
class KeptVersionsBanner extends ConsumerWidget {
  const KeptVersionsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(keptVersionsProvider).valueOrNull?.length ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      tileColor: Theme.of(context).colorScheme.errorContainer,
      leading: const Icon(Icons.call_split, size: 18),
      title: Text(AppLocalizations.of(context)!.syncKeptBanner(count)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const KeptVersionsScreen(),
      )),
    );
  }
}

class KeptVersionsScreen extends ConsumerWidget {
  const KeptVersionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final kept = ref.watch(keptVersionsProvider).valueOrNull ?? const <KeptVersion>[];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncKeptTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.syncKeptExplain),
          ),
          if (kept.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.syncKeptEmpty, textAlign: TextAlign.center),
            ),
          for (final k in kept)
            ListTile(
              leading: const Icon(Icons.call_split),
              title: Text(k.record.name.isNotEmpty ? k.record.name : l10n.btkNumber(k.record.id)),
              subtitle: Text(shortDate(k.keptAt)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _review(context, ref, k),
            ),
        ],
      ),
    );
  }

  void _review(BuildContext context, WidgetRef ref, KeptVersion kept) {
    final l10n = AppLocalizations.of(context)!;
    BtkRecord? current;
    for (final r in ref.read(btkProvider)) {
      if (r.id == kept.record.id) current = r;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CompareScreen(
        title: l10n.syncKeptTitle,
        records: [?current, kept.record],
        titles: [if (current != null) l10n.syncKeptCurrent, l10n.syncKeptOther],
        bottomBar: _Decision(kept: kept, hasCurrent: current != null),
      ),
    ));
  }
}

class _Decision extends ConsumerWidget {
  final KeptVersion kept;
  final bool hasCurrent;

  const _Decision({required this.kept, required this.hasCurrent});

  Future<bool> _confirm(BuildContext context, String text) async {
    final l10n = AppLocalizations.of(context)!;
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.continueAction),
          ),
        ],
      ),
    );
    return answer == true;
  }

  // The kept version goes only once the action has worked.
  Future<void> _finish(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
      await ConflictStore.instance.removeKept(kept.id);
    } catch (_) {
      AppMessenger.showError((l10n) => l10n.syncActionFailed);
      return;
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final records = ref.read(btkProvider.notifier);

    final keepCurrent = OutlinedButton(
      onPressed: () async {
        if (await _confirm(context, l10n.syncKeepCurrentConfirm) && context.mounted) {
          await _finish(context, () async {});
        }
      },
      child: Text(l10n.syncKeepCurrent),
    );
    final replace = OutlinedButton(
      onPressed: () async {
        if (await _confirm(context, l10n.syncKeepOtherConfirm) && context.mounted) {
          await _finish(context, () => records.restoreKept(kept.record));
        }
      },
      child: Text(l10n.syncKeepOther),
    );
    final keepBoth = FilledButton(
      onPressed: () => _finish(
        context,
        () => records.duplicate(kept.record, l10n.copySuffix),
      ),
      child: Text(l10n.syncKeepBoth),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: hasCurrent
            ? Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [keepBoth, replace, keepCurrent],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.syncKeptNoCurrent, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () =>
                            _finish(context, () => records.restoreKept(kept.record)),
                        child: Text(l10n.syncRestore),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          if (await _confirm(context, l10n.syncKeepCurrentConfirm) &&
                              context.mounted) {
                            await _finish(context, () async {});
                          }
                        },
                        child: Text(l10n.delete),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
