import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/btk_record.dart';
import '../domain/btk_provider.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/export_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/domain/settings_provider.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BtkRecord> _filter(List<BtkRecord> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((r) {
      return r.id.toLowerCase().contains(q) ||
          r.location.toLowerCase().contains(q) ||
          r.date.toString().split(' ').first.contains(q) ||
          (r.latitude?.toStringAsFixed(4).contains(q) ?? false) ||
          r.geologicalFormation.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(btkProvider);
    final records = _filter(all);

    return Scaffold(
      appBar: AppBar(
        title: const Text('შენახული ჩანაწერები'),
        actions: [
          if (all.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'ექსპორტი',
              onSelected: (val) => _export(val, all),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'geojson',
                  child: ListTile(
                    leading: Icon(Icons.map_outlined),
                    title: Text('GeoJSON (QGIS)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'csv',
                  child: ListTile(
                    leading: Icon(Icons.table_chart_outlined),
                    title: Text('CSV (Excel/Sheets)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf_outlined),
                    title: Text('PDF დოკუმენტი'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'ძებნა: ID, ლოკაცია, თარიღი...',
              leading: const Icon(Icons.search, size: 20),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
              elevation: const WidgetStatePropertyAll(1),
              padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12)),
            ),
          ),
        ),
      ),
      body: records.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _query.isEmpty
                        ? Icons.article_outlined
                        : Icons.search_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _query.isEmpty
                        ? 'ჩანაწერები არ მოიძებნა'
                        : '"$_query" — არ მოიძებნა',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: records.length,
              itemBuilder: (context, i) => _RecordTile(
                record: records[i],
                onDelete: () => _confirmDelete(context, records[i].id),
              ),
            ),
    );
  }

  Future<void> _export(String format, List<BtkRecord> records) async {
    final coordFmt = ref.read(settingsProvider).exportCoordFormat;
    try {
      if (format == 'geojson') {
        await ExportService.shareGeoJson(records);
      } else if (format == 'csv') {
        await ExportService.shareCsv(records, coordFormat: coordFmt);
      } else if (format == 'pdf') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('PDF მზადდება...'),
            duration: Duration(seconds: 2),
          ));
        }
        await ExportService.sharePdf(records);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('შეცდომა: $e')));
      }
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: const Text('დარწმუნებული ხართ ამ ჩანაწერის წაშლაში?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(btkProvider.notifier).remove(id);
              AnalyticsService.logRecordDeleted();
              Navigator.pop(ctx);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Record tile ─────────────────────────────────────────────────────────────

class _RecordTile extends ConsumerWidget {
  final BtkRecord record;
  final VoidCallback onDelete;

  const _RecordTile({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = record;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            r.id.substring(0, 2),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text('ბტკ #${r.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.date.toString().split(' ')[0]),
            if (r.location.isNotEmpty) Text(r.location),
            if (r.latitude != null)
              Text(
                '${r.latitude!.toStringAsFixed(4)}, '
                '${r.longitude!.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20),
              tooltip: 'გაზიარება',
              onPressed: () async {
                try {
                  await ExportService.sharePdf([r]);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('შეცდომა: $e')));
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: () => context.push('/form', extra: r),
      ),
    );
  }
}
