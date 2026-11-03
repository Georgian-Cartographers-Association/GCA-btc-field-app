import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/btk_provider.dart';
import '../domain/record_filter.dart';

Future<void> showRecordFilterSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RecordFilterSheet(),
    );

class _RecordFilterSheet extends ConsumerWidget {
  const _RecordFilterSheet();

  String _day(DateTime d) => d.toString().split(' ').first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final records = ref.watch(btkProvider);
    final filter = ref.watch(recordFilterProvider);
    final set = ref.read(recordFilterProvider.notifier);
    final groups = groupsIn(records);
    final hasUngrouped = records.any((r) => r.group.trim().isEmpty);

    void toggle(String group) {
      final next = {...filter.groups};
      if (!next.remove(group)) next.add(group);
      set.state = RecordFilter(
          groups: next, unfinishedOnly: filter.unfinishedOnly, dates: filter.dates);
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.filterTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: filter.isActive
                      ? () => set.state = const RecordFilter()
                      : null,
                  child: Text(l10n.filterClear),
                ),
              ],
            ),
            Text(
              l10n.filterShown(filter.apply(records).length, records.length),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(l10n.recordGroup),
            const SizedBox(height: 4),
            if (groups.isEmpty) Text(l10n.noGroupsYet, style: Theme.of(context).textTheme.bodySmall),
            Wrap(
              spacing: 6,
              children: [
                for (final g in groups)
                  FilterChip(
                    avatar: CircleAvatar(backgroundColor: groupColor(g), radius: 6),
                    label: Text(g),
                    selected: filter.groups.contains(g),
                    onSelected: (_) => toggle(g),
                  ),
                if (groups.isNotEmpty && hasUngrouped)
                  FilterChip(
                    label: Text(l10n.noGroup),
                    selected: filter.groups.contains(''),
                    onSelected: (_) => toggle(''),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.filterUnfinished),
              value: filter.unfinishedOnly,
              onChanged: (v) => set.state = RecordFilter(
                  groups: filter.groups, unfinishedOnly: v, dates: filter.dates),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range),
              title: Text(filter.dates == null
                  ? l10n.filterAnyDate
                  : '${_day(filter.dates!.start)} – ${_day(filter.dates!.end)}'),
              trailing: filter.dates == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.filterClear,
                      onPressed: () => set.state = RecordFilter(
                          groups: filter.groups, unfinishedOnly: filter.unfinishedOnly),
                    ),
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: filter.dates,
                );
                if (picked != null) {
                  set.state = RecordFilter(
                      groups: ref.read(recordFilterProvider).groups,
                      unfinishedOnly: ref.read(recordFilterProvider).unfinishedOnly,
                      dates: picked);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
