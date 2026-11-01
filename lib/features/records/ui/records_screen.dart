import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/btk_record.dart';
import '../domain/btk_provider.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/export_service.dart';
import '../../../data/services/update_service.dart';
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
  bool _selectionMode = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) UpdateService.checkAndNotify(context);
    });
  }

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
          r.name.toLowerCase().contains(q) ||
          r.location.toLowerCase().contains(q) ||
          r.date.toString().split(' ').first.contains(q) ||
          (r.latitude?.toStringAsFixed(4).contains(q) ?? false) ||
          r.geologicalFormation.toLowerCase().contains(q);
    }).toList();
  }

  // ── Selection helpers ────────────────────────────────────────────────────────

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        if (_selected.isEmpty) _selectionMode = false;
      } else {
        _selected.add(id);
      }
    });
  }

  void _enterSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selected.add(id);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
  }

  List<BtkRecord> _selectedRecords() {
    final all = ref.read(btkProvider);
    return all.where((r) => _selected.contains(r.id)).toList();
  }

  // ── Batch actions ────────────────────────────────────────────────────────────

  Future<void> _exportSelected() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ExportService.exportBtk(_selectedRecords(), context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorWithDetail('$e'))));
      }
    }
  }

  Future<void> _pdfSelected() async {
    if (mounted) await _pdfActionSheet(context, _selectedRecords());
  }

  Future<void> _deleteSelected() async {
    final l10n = AppLocalizations.of(context)!;
    final count = _selected.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteRecordsConfirm(count)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete,
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    for (final id in _selected.toList()) {
      await ref.read(btkProvider.notifier).remove(id);
    }
    _clearSelection();
  }

  // ── Per-record actions ───────────────────────────────────────────────────────

  Future<void> _duplicate(BtkRecord r) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(btkProvider.notifier).duplicate(r, l10n.copySuffix);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.recordDuplicated),
          duration: Duration(seconds: 2)));
    }
  }

  // ── Export / import ──────────────────────────────────────────────────────────

  Future<void> _export(String format, List<BtkRecord> records) async {
    final l10n = AppLocalizations.of(context)!;
    final coordFmt = ref.read(settingsProvider).exportCoordFormat;
    try {
      switch (format) {
        case 'btk':
          await ExportService.exportBtk(records, context);
        case 'btkz':
          await ExportService.exportBtkz(records, context);
        case 'kml':
          await ExportService.shareKml(records, l10n);
        case 'geojson':
          await ExportService.shareGeoJson(records, l10n);
        case 'csv':
          await ExportService.shareCsv(records, l10n, coordFormat: coordFmt);
        case 'pdf':
          if (mounted) await _pdfActionSheet(context, records);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorWithDetail('$e'))));
      }
    }
  }

  Future<void> _importAny() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.fileType,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.import_export_outlined),
              title: Text(l10n.btkFileTitle),
              subtitle: Text(l10n.btkFileSub),
              onTap: () => Navigator.pop(context, 'btk'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.btkzFileTitle),
              subtitle: Text(l10n.btkzFileSub),
              onTap: () => Navigator.pop(context, 'btkz'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    try {
      if (choice == 'btkz') {
        final r = await ExportService.parseBtkzFile(l10n);
        if (r == null) return;
        final imported =
            await ref.read(btkProvider.notifier).importRecords(r.records);
        if (mounted) {
          final parts = [
            l10n.recordsCount(imported.added + imported.updated),
            if (r.photoCount > 0) l10n.photosCount(r.photoCount),
            if (r.trackCount > 0) l10n.tracksCount(r.trackCount),
          ].join(', ');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.importedParts(parts)),
            duration: const Duration(seconds: 4),
          ));
        }
      } else {
        final records = await ExportService.parseBtkFile(l10n);
        if (records == null) return;
        final imported =
            await ref.read(btkProvider.notifier).importRecords(records);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                l10n.importedSummary(imported.added + imported.updated,
                    imported.added, imported.updated)),
            duration: const Duration(seconds: 4),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorWithDetail('$e'))));
      }
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteRecordConfirm),
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
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final all = ref.watch(btkProvider);
    final records = _filter(all);

    return Scaffold(
      appBar: _selectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text(l10n.recordsCount(_selected.length)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.import_export_outlined),
                  tooltip: l10n.exportBtc,
                  onPressed: _exportSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'PDF',
                  onPressed: _pdfSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: l10n.delete,
                  onPressed: _deleteSelected,
                ),
              ],
            )
          : AppBar(
              title: Text(l10n.savedRecords),
              actions: [
                IconButton(
                  icon: const Icon(Icons.bar_chart_outlined),
                  tooltip: l10n.statistics,
                  onPressed: () => context.push('/stats'),
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file_outlined),
                  tooltip: l10n.importAction,
                  onPressed: _importAny,
                ),
                if (all.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: l10n.exportAction,
                    onSelected: (val) => _export(val, all),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'btk',
                        child: ListTile(
                          leading: Icon(Icons.import_export_outlined),
                          title: Text(l10n.btkFileTitle),
                          subtitle: Text(l10n.btkFileSub),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'btkz',
                        child: ListTile(
                          leading: Icon(Icons.photo_library_outlined),
                          title: Text(l10n.btkzFileTitle),
                          subtitle: Text(l10n.btkzFileSub),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: ListTile(
                          leading: Icon(Icons.picture_as_pdf_outlined),
                          title: Text(l10n.pdfDocument),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'kml',
                        child: ListTile(
                          leading: Icon(Icons.public_outlined),
                          title: Text('KML (Google Earth)'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
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
                    ],
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: SearchBar(
                    controller: _searchCtrl,
                    hintText: l10n.recordsSearchHint,
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
                        ? l10n.noRecords
                        : l10n.queryNotFound(_query),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: records.length,
              itemBuilder: (context, i) {
                final r = records[i];
                return _RecordTile(
                  record: r,
                  selectionMode: _selectionMode,
                  isSelected: _selected.contains(r.id),
                  onToggleSelect: () => _toggleSelect(r.id),
                  onLongPress: () => _enterSelection(r.id),
                  onDuplicate: () => _duplicate(r),
                  onDelete: () => _confirmDelete(context, r.id),
                );
              },
            ),
    );
  }
}

// ── PDF action sheet ──────────────────────────────────────────────────────────

Future<void> _pdfActionSheet(
    BuildContext context, List<BtkRecord> records) async {
      final l10n = AppLocalizations.of(context)!;
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: Text(l10n.share),
            onTap: () => Navigator.pop(context, 'share'),
          ),
          ListTile(
            leading: const Icon(Icons.save_alt_outlined),
            title: Text(l10n.saveAsFile),
            onTap: () => Navigator.pop(context, 'save'),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  if (context.mounted) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.pdfPreparing),
      duration: Duration(seconds: 3),
    ));
  }
  if (choice == 'share') {
    final l10n = AppLocalizations.of(context)!;
    await ExportService.sharePdf(records, l10n);
  } else {
    await ExportService.savePdf(records, context);
  }
}

// ── Record tile ───────────────────────────────────────────────────────────────

class _RecordTile extends ConsumerWidget {
  final BtkRecord record;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onLongPress;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _RecordTile({
    required this.record,
    required this.selectionMode,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onLongPress,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final r = record;
    final hasName = r.name.isNotEmpty;

    return Card(
      child: ListTile(
        selected: selectionMode && isSelected,
        leading: selectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelect(),
              )
            : CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  r.id.substring(0, 2),
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
        title: Text(hasName ? r.name : l10n.btkNumber(r.id)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasName)
              Text(l10n.btkNumber(r.id),
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(r.date.toString().split(' ')[0]),
            if (r.location.isNotEmpty) Text(r.location),
            if (r.latitude != null)
              Text(
                '${r.latitude!.toStringAsFixed(4)}, '
                '${r.longitude!.toStringAsFixed(4)}',
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: selectionMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined,
                        size: 20),
                    tooltip: 'PDF',
                    onPressed: () => _pdfActionSheet(context, [r]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 20),
                    tooltip: l10n.duplicate,
                    onPressed: onDuplicate,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
        onTap: selectionMode
            ? onToggleSelect
            : () => context.push('/form', extra: r),
        onLongPress: selectionMode ? null : onLongPress,
      ),
    );
  }
}
