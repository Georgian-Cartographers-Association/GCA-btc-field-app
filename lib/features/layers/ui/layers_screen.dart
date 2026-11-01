import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show File, Directory;
import '../../../models/tile_service.dart';
import '../../raster/domain/raster_provider.dart';
import '../../map/domain/tile_service_provider.dart';
import '../../../data/services/analytics_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class LayersScreen extends ConsumerStatefulWidget {
  const LayersScreen({super.key});

  @override
  ConsumerState<LayersScreen> createState() => _LayersScreenState();
}

class _LayersScreenState extends ConsumerState<LayersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dataLayers),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(icon: Icon(Icons.image_outlined), text: l10n.rasters),
            Tab(icon: Icon(Icons.public), text: l10n.webServices),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _RasterTab(),
          _TileServiceTab(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 1: Rasters
// ══════════════════════════════════════════════════════════════════════════════

class _RasterTab extends ConsumerStatefulWidget {
  const _RasterTab();

  @override
  ConsumerState<_RasterTab> createState() => _RasterTabState();
}

class _RasterTabState extends ConsumerState<_RasterTab> {
  bool _picking = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final layers = ref.watch(rasterProvider);
    final notifier = ref.read(rasterProvider.notifier);

    return Column(
      children: [
        // ─ "From device" button ─
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _picking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.folder_open_outlined),
              label: Text(l10n.fromDevice),
              onPressed: _picking ? null : () => _pickRasterFile(context),
            ),
          ),
        ),
        const Divider(height: 1),

        // ─ List ─
        Expanded(
          child: layers.isEmpty
              ? _EmptyRasterHint()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: layers.length,
                  itemBuilder: (ctx, i) {
                    final layer = layers[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: layer.visible
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Colors.grey.shade200,
                              child: Icon(
                                layer.isDeviceLayer
                                    ? Icons.folder_outlined
                                    : Icons.image_outlined,
                                color: layer.visible
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                            title: Text(layer.name),
                            subtitle: Text(
                              'N:${layer.northLat.toStringAsFixed(3)}  '
                              'S:${layer.southLat.toStringAsFixed(3)}  '
                              'E:${layer.eastLon.toStringAsFixed(3)}  '
                              'W:${layer.westLon.toStringAsFixed(3)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: layer.visible,
                                  onChanged: (_) {
                                    notifier.toggleVisible(layer.id);
                                    AnalyticsService.logLayerToggled(
                                        'raster:${layer.name}', !layer.visible);
                                  },
                                ),
                                if (layer.isDeviceLayer)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: Colors.red),
                                    onPressed: () =>
                                        notifier.removeDevice(layer.id),
                                  ),
                              ],
                            ),
                          ),
                          if (layer.visible)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.opacity,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Slider(
                                      value: layer.opacity,
                                      min: 0.1,
                                      max: 1.0,
                                      divisions: 18,
                                      label:
                                          '${(layer.opacity * 100).round()}%',
                                      onChanged: (v) =>
                                          notifier.setOpacity(layer.id, v),
                                    ),
                                  ),
                                  Text('${(layer.opacity * 100).round()}%',
                                      style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _pickRasterFile(BuildContext context) async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'tif', 'tiff'],
        withData: kIsWeb,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;

      if (!context.mounted) return;
      final bounds = await _showBoundsDialog(context, file.name);
      if (bounds == null) return;

      String? savedPath;
      Uint8List? bytes = file.bytes;

      // On Android/desktop: copy to documents dir for persistence
      if (!kIsWeb && file.path != null) {
        try {
          final docs = await getApplicationDocumentsDirectory();
          final dir = Directory('${docs.path}/rasters');
          await dir.create(recursive: true);
          final dest = '${dir.path}/${const Uuid().v4().substring(0, 8)}_${file.name}';
          await File(file.path!).copy(dest);
          savedPath = dest;
        } catch (_) {
          savedPath = file.path;
        }
      }

      if (!mounted) return;
      await ref.read(rasterProvider.notifier).addFromFile(
            name: bounds.$1,
            north: bounds.$2,
            south: bounds.$3,
            east: bounds.$4,
            west: bounds.$5,
            filePath: savedPath,
            fileBytes: kIsWeb ? bytes : null,
          );
      AnalyticsService.logRasterAdded(kIsWeb ? 'web' : 'device');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// Returns (name, north, south, east, west) or null if cancelled.
  Future<(String, double, double, double, double)?> _showBoundsDialog(
      BuildContext context, String filename) {
        final l10n = AppLocalizations.of(context)!;
    final nameCtrl =
        TextEditingController(text: filename.replaceAll(RegExp(r'\.\w+$'), ''));
    final nCtrl = TextEditingController();
    final sCtrl = TextEditingController();
    final eCtrl = TextEditingController();
    final wCtrl = TextEditingController();

    return showDialog<(String, double, double, double, double)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rasterBounds),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BoundsField(controller: nameCtrl, label: l10n.name),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: _BoundsField(
                        controller: nCtrl, label: l10n.boundNorth, isNum: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _BoundsField(
                        controller: sCtrl, label: l10n.boundSouth, isNum: true)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: _BoundsField(
                        controller: eCtrl, label: l10n.boundEast, isNum: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _BoundsField(
                        controller: wCtrl, label: l10n.boundWest, isNum: true)),
              ]),
              const SizedBox(height: 4),
              Text(
                l10n.boundsExample,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              final n = double.tryParse(nCtrl.text.trim());
              final s = double.tryParse(sCtrl.text.trim());
              final e = double.tryParse(eCtrl.text.trim());
              final w = double.tryParse(wCtrl.text.trim());
              if (n == null || s == null || e == null || w == null) return;
              final name = nameCtrl.text.trim().isEmpty ? filename : nameCtrl.text.trim();
              Navigator.pop(ctx, (name, n, s, e, w));
            },
            child: Text(l10n.addEmail),
          ),
        ],
      ),
    );
  }
}

class _BoundsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isNum;
  const _BoundsField(
      {required this.controller, required this.label, this.isNum = false});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType:
            isNum ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
        ),
      );
}

class _EmptyRasterHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_search, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(l10n.noRasterLayers,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.layersEmptyHelp,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace', color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 2: WMS / WMTS / XYZ Tile Services
// ══════════════════════════════════════════════════════════════════════════════

class _TileServiceTab extends ConsumerWidget {
  const _TileServiceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final services = ref.watch(tileServiceProvider);
    final notifier = ref.read(tileServiceProvider.notifier);

    return Column(
      children: [
        // ─ Add buttons ─
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.playlist_add),
                  label: Text(l10n.fromTemplate),
                  onPressed: () => _showTemplateDialog(context, ref),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_link),
                  label: const Text('Custom URL'),
                  onPressed: () => _showAddDialog(context, ref),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ─ List ─
        Expanded(
          child: services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(l10n.noWebServices,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Text('XYZ · WMTS · WMS',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: services.length,
                  itemBuilder: (ctx, i) {
                    final svc = services[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: svc.visible
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Colors.grey.shade200,
                              child: Icon(
                                svc.serviceType == ServiceType.wms
                                    ? Icons.layers_outlined
                                    : Icons.public,
                                color: svc.visible
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                            title: Text(svc.name),
                            subtitle: Text(
                              '${svc.serviceType.name.toUpperCase()}  ${svc.urlTemplate}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: svc.visible,
                                  onChanged: (_) {
                                    notifier.toggleVisible(svc.id);
                                    AnalyticsService.logLayerToggled(
                                        'tile:${svc.name}', !svc.visible);
                                  },
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (action) {
                                    switch (action) {
                                      case 'edit':
                                        _showEditDialog(context, ref, svc);
                                        break;
                                      case 'template':
                                        _saveAsTemplate(context, svc);
                                        break;
                                      case 'delete':
                                        _confirmDelete(context, ref, svc.id);
                                        break;
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(
                                            dense: true,
                                            leading: Icon(Icons.edit_outlined),
                                            title: Text(l10n.editRecord))),
                                    PopupMenuItem(
                                        value: 'template',
                                        child: ListTile(
                                            dense: true,
                                            leading: Icon(Icons.bookmark_add_outlined),
                                            title: Text(l10n.saveAsTemplate))),
                                    PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                            dense: true,
                                            leading: Icon(Icons.delete_outline,
                                                color: Colors.red),
                                            title: Text(l10n.delete,
                                                style: TextStyle(
                                                    color: Colors.red)))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (svc.visible)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.opacity,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Slider(
                                      value: svc.opacity,
                                      min: 0.1,
                                      max: 1.0,
                                      divisions: 18,
                                      label:
                                          '${(svc.opacity * 100).round()}%',
                                      onChanged: (v) =>
                                          notifier.setOpacity(svc.id, v),
                                    ),
                                  ),
                                  Text('${(svc.opacity * 100).round()}%',
                                      style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showTemplateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _TemplateSheet(
        onSelected: (tpl, name) {
          ref.read(tileServiceProvider.notifier).addFromTemplate(tpl, name);
          AnalyticsService.logTileServiceAdded('template');
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _TileServiceDialog(
        onSave: (svc) {
          ref.read(tileServiceProvider.notifier).add(svc);
          AnalyticsService.logTileServiceAdded(svc.serviceType.name); // 'xyz' or 'wms'
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, TileService svc) {
    showDialog(
      context: context,
      builder: (ctx) => _TileServiceDialog(
        initial: svc,
        onSave: (updated) {
          ref.read(tileServiceProvider.notifier).update(updated);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _saveAsTemplate(BuildContext context, TileService svc) async {
    final l10n = AppLocalizations.of(context)!;
    await TileServiceNotifier.saveAsTemplate(svc);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.templateSaved(svc.name)),
            duration: const Duration(seconds: 2)),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteServiceConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.no)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(tileServiceProvider.notifier).remove(id);
              Navigator.pop(ctx);
            },
            child:
                Text(l10n.delete, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Template picker bottom sheet
// ──────────────────────────────────────────────────────────────────────────────

class _TemplateSheet extends StatefulWidget {
  final void Function(Map<String, dynamic> tpl, String name) onSelected;
  const _TemplateSheet({required this.onSelected});

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  int? _selected;
  final _nameCtrl = TextEditingController();
  List<Map<String, dynamic>> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final all = await TileServiceNotifier.loadAllTemplates();
    if (mounted) setState(() { _templates = all; _loading = false; });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.chooseTemplate,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ...(_templates.asMap().entries.map((e) {
              final isCustom = e.value['isCustom'] == true;
              return ListTile(
                dense: true,
                leading: Radio<int>(
                  value: e.key,
                  groupValue: _selected,
                  onChanged: (v) => setState(() {
                    _selected = v;
                    if (_nameCtrl.text.isEmpty || _nameCtrl.text == _templates[_selected ?? 0]['name']) {
                      _nameCtrl.text = e.value['name'] as String;
                    }
                  }),
                ),
                title: Row(
                  children: [
                    Text(e.value['name'] as String),
                    if (isCustom) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('custom',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondaryContainer)),
                      ),
                    ],
                    if (isCustom) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await TileServiceNotifier.removeCustomTemplate(
                              e.value['name'] as String);
                          _loadTemplates();
                        },
                        child: const Icon(Icons.close, size: 16, color: Colors.red),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${(e.value['serviceType'] as String? ?? 'xyz').toUpperCase()}  '
                  '${e.value['urlTemplate']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
                onTap: () => setState(() {
                  _selected = e.key;
                  _nameCtrl.text = e.value['name'] as String;
                }),
              );
            })),

          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: l10n.nameOptional,
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selected == null
                  ? null
                  : () => widget.onSelected(
                        _templates[_selected!],
                        _nameCtrl.text.trim(),
                      ),
              child: Text(l10n.addEmail),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Add / Edit tile service dialog — supports XYZ and WMS types
// ──────────────────────────────────────────────────────────────────────────────

class _TileServiceDialog extends StatefulWidget {
  final TileService? initial;
  final void Function(TileService) onSave;
  const _TileServiceDialog({this.initial, required this.onSave});

  @override
  State<_TileServiceDialog> createState() => _TileServiceDialogState();
}

class _TileServiceDialogState extends State<_TileServiceDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _subCtrl;
  late TextEditingController _wmsLayersCtrl;
  late ServiceType _type;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _urlCtrl = TextEditingController(text: s?.urlTemplate ?? '');
    _subCtrl = TextEditingController(text: s?.subdomains.join(',') ?? '');
    _wmsLayersCtrl = TextEditingController(text: s?.wmsLayers ?? '');
    _type = s?.serviceType ?? ServiceType.xyz;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _subCtrl.dispose();
    _wmsLayersCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.initial == null ? l10n.addService : l10n.editService),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(_nameCtrl, l10n.name),
            const SizedBox(height: 12),

            // Type selector
            Text(l10n.type, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            SegmentedButton<ServiceType>(
              segments: const [
                ButtonSegment(value: ServiceType.xyz, label: Text('XYZ / WMTS')),
                ButtonSegment(value: ServiceType.wms, label: Text('WMS')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 10),

            if (_type == ServiceType.xyz) ...[
              _field(_urlCtrl, l10n.urlTemplate,
                  hint: 'https://example.com/{z}/{x}/{y}.png'),
              const SizedBox(height: 10),
              _field(_subCtrl, l10n.subdomains,
                  hint: l10n.subdomainsHint),
            ] else ...[
              _field(_urlCtrl, l10n.wmsServiceUrl,
                  hint: 'https://example.com/wms'),
              const SizedBox(height: 10),
              _field(_wmsLayersCtrl, l10n.wmsLayers,
                  hint: 'layer1,layer2'),
              const SizedBox(height: 6),
              Text(
                l10n.wmsAutoRequest,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _save() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    final subs = _subCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final svc = TileService(
      id: widget.initial?.id ?? const Uuid().v4().substring(0, 8),
      name: _nameCtrl.text.trim().isEmpty ? url : _nameCtrl.text.trim(),
      serviceType: _type,
      urlTemplate: url,
      subdomains: subs,
      wmsLayers: _wmsLayersCtrl.text.trim(),
      opacity: widget.initial?.opacity ?? 1.0,
      visible: widget.initial?.visible ?? true,
    );
    widget.onSave(svc);
  }

  Widget _field(TextEditingController c, String label, {String? hint}) =>
      TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
      );
}
