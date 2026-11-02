import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_messenger.dart';
import '../../../models/btk_record.dart';
import '../../../models/record_quality.dart';
import '../../records/domain/btk_provider.dart';
import '../../settings/domain/settings_provider.dart';
import '../../../data/services/analytics_service.dart';
import '../../pdf/ui/pdf_viewer_screen.dart';
import 'sections/photos_section.dart';
import 'sections/basic_info_section.dart';
import 'sections/physical_geo_section.dart';
import 'sections/vegetation_section.dart';
import 'sections/soil_section.dart';
import 'sections/geomass_section.dart';
import 'sections/vertical_structure_section.dart';
import 'widgets/record_tools.dart';

class BtkFormScreen extends ConsumerStatefulWidget {
  final BtkRecord record;
  const BtkFormScreen({super.key, required this.record});

  @override
  ConsumerState<BtkFormScreen> createState() => _BtkFormScreenState();
}

class _BtkFormScreenState extends ConsumerState<BtkFormScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late BtkRecord _record;
  late TabController _tabController;
  bool _pdfOpen = false;
  bool _dirty = false; // unsaved changes indicator

  bool _saveFailureShown = false;

  // The record as it was opened, for "undo changes".
  late final String _opened;

  // Sections keep their own text controllers, so anything that changes the
  // record from outside them has to recreate them.
  int _generation = 0;

  // Auto-save debounce — 800 ms after last change
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _opened = _snapshot(_record);
    WidgetsBinding.instance.addObserver(this);
    // 7 tabs on Android (photos available), 6 on web
    _tabController = TabController(length: kIsWeb ? 6 : 7, vsync: this);
  }

  // Everything the user can edit, leaving out the save time.
  String _snapshot(BtkRecord r) => jsonEncode(r.toJson()..remove('updatedAt'));

  // Android may end the app at any time once it's in the background, for
  // example while the camera is open, so a pending save can't wait.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _autoSaveTimer?.isActive == true) {
      _autoSaveTimer!.cancel();
      _autoSave();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Flush any pending auto-save immediately on screen close
    if (_autoSaveTimer?.isActive == true) {
      _autoSaveTimer!.cancel();
      // fire-and-forget — we're leaving the widget tree
      ref.read(btkProvider.notifier).update(_record).catchError((Object _) {
        AppMessenger.showError((l10n) => l10n.saveFailed);
        return false;
      });
    }
    _tabController.dispose();
    super.dispose();
  }

  // Called by every section widget on any field change
  void _update(BtkRecord updated) {
    setState(() {
      _record = updated;
      _dirty = true;
    });
    // Debounce auto-save
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), _autoSave);
  }

  // Silent background save — conflict ignored (auto-save is non-intrusive)
  // A failure is shown once per failing streak, and the unsaved dot stays on.
  Future<void> _autoSave() async {
    try {
      await ref.read(btkProvider.notifier).update(_record);
    } catch (_) {
      if (!_saveFailureShown) {
        _saveFailureShown = true;
        AppMessenger.showError((l10n) => l10n.saveFailed);
      }
      return;
    }
    _saveFailureShown = false;
    if (mounted) setState(() => _dirty = false);
  }

  // Explicit save — shows conflict warning in expedition mode
  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    _autoSaveTimer?.cancel();
    final bool conflict;
    try {
      conflict = await ref.read(btkProvider.notifier).update(_record);
    } catch (_) {
      AppMessenger.showError((l10n) => l10n.saveFailed);
      return;
    }
    _saveFailureShown = false;
    AnalyticsService.logRecordSaved();
    if (!mounted) return;
    setState(() => _dirty = false);
    if (conflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.otherUserChanged,
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.savedCheck), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _detectGps() async {
    final l10n = AppLocalizations.of(context)!;
    // 1. Check if GPS hardware/service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      final open = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.gpsOff),
          content: Text(
              l10n.gpsOffMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.enableGps),
            ),
          ],
        ),
      );
      if (open == true) await Geolocator.openLocationSettings();
      return;
    }

    // 2. Check / request permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (!mounted) return;
      final open = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.locationBlocked),
          content: Text(
              l10n.locationBlockedMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.settings),
            ),
          ],
        ),
      );
      if (open == true) await Geolocator.openAppSettings();
      return;
    }
    if (perm == LocationPermission.denied) return;

    if (!mounted) return;
    if (_record.latitude != null || _record.longitude != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.replaceCoordsTitle),
          content: Text(l10n.replaceCoordsMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.replaceAction),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.locationDetecting),
        duration: Duration(seconds: 2)));
    final Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 30),
        ),
      );
    } catch (_) {
      AppMessenger.showError((l10n) => l10n.locationFailed);
      return;
    }
    if (!mounted) return;

    double? heading;
    if (!kIsWeb) {
      try {
        final event = await FlutterCompass.events!
            .first
            .timeout(const Duration(seconds: 3));
        heading = event.heading;
      } catch (_) {
        heading = null;
      }
      if (!mounted) return;
    }

    _update(_record
      ..latitude = pos.latitude
      ..longitude = pos.longitude
      ..altitude = pos.altitude
      ..aspect = heading ?? _record.aspect);
  }

  // ─── Email sending ──────────────────────────────────────────────────────────

  Future<void> _sendEmail() async {
    final emails = ref.read(settingsProvider).emails;

    List<String> targets;
    if (emails.isEmpty) {
      final entered = await _askEmailManually();
      if (entered == null || entered.isEmpty) return;
      targets = [entered];
    } else if (emails.length == 1) {
      targets = emails;
    } else {
      // Let user pick which emails to send to
      targets = await _pickEmails(emails) ?? [];
      if (targets.isEmpty) return;
    }

    final to = targets.join(',');
    final subject = Uri.encodeComponent(
        'ბტკ ჩანაწერი ${_record.id} — ${_record.date.toString().split(' ')[0]}');
    final body = Uri.encodeComponent(_record.toEmailText());
    final uri = Uri.parse('mailto:$to?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      AnalyticsService.logEmailSent(targets.length);
    }
  }

  Future<List<String>?> _pickEmails(List<String> all) {
    final l10n = AppLocalizations.of(context)!;
    final selected = <String>{...all}; // all selected by default
    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l10n.send),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: all
                .map((e) => CheckboxListTile(
                      value: selected.contains(e),
                      title: Text(e),
                      dense: true,
                      onChanged: (v) => setS(() {
                        if (v == true) {
                          selected.add(e);
                        } else {
                          selected.remove(e);
                        }
                      }),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected.toList()),
              child: Text(l10n.send),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _askEmailManually() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.emailAddress),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(hintText: 'example@email.com'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.paste),
              tooltip: l10n.paste,
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) controller.text = data!.text!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.send),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return; // already navigated (canPop was true)
        // Leaving keeps the edits, as autosave would. Undoing them is a separate
        // action, so a mistaken tap on the way out can't lose field data.
        if (!mounted) return;
        _autoSaveTimer?.cancel();
        try {
          await ref.read(btkProvider.notifier).update(_record);
        } catch (_) {
          if (!mounted) return;
          final leave = await showDialog<bool>(
            context: context,
            builder: (dCtx) => AlertDialog(
              title: Text(l10n.recordChanged),
              content: Text(l10n.exitSaveFailed),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx, true),
                  child: Text(l10n.exitAction,
                      style: const TextStyle(color: Colors.red)),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dCtx, false),
                  child: Text(l10n.stay),
                ),
              ],
            ),
          );
          if (leave != true || !mounted) return;
        }
        if (!mounted) return;
        setState(() => _dirty = false);
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(l10n.btkNumber(_record.id)),
              if (_dirty) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            Builder(builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.menu_book_outlined),
                  tooltip: l10n.methodology,
                  onPressed: () => setState(() => _pdfOpen = !_pdfOpen),
                ),
                _qualityButton(l10n),
                IconButton(
                  icon: const Icon(Icons.save_outlined),
                  tooltip: l10n.save,
                  onPressed: _save,
                ),
                PopupMenuButton<VoidCallback>(
                  tooltip: l10n.recordMenu,
                  onSelected: (action) => action(),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: _fillFromOther, child: Text(l10n.fillFromOther)),
                    PopupMenuItem(value: _saveTemplate, child: Text(l10n.recordSaveAsTemplate)),
                    PopupMenuItem(value: _sendEmail, child: Text(l10n.send)),
                    PopupMenuItem(
                      value: _revert,
                      enabled: _snapshot(_record) != _opened,
                      child: Text(l10n.revertChanges),
                    ),
                  ],
                ),
              ]);
            }),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              for (final section in FormSection.values) _sectionTab(l10n, section),
              if (!kIsWeb)
                Tab(
                  icon: Icon(Icons.photo_library_outlined, size: 16),
                  text: l10n.photos,
                ),
            ],
          ),
        ),
        body: _pdfOpen
            ? _SplitView(
                form: _buildTabView(),
                onClose: () => setState(() => _pdfOpen = false),
              )
            : _buildTabView(),
        floatingActionButton: _pdfOpen
            ? null
            : FloatingActionButton.extended(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(AppLocalizations.of(context)!.save),
              ),
      ),
    );
  }

  // A tick shows at a glance which sections still need work.
  Widget _sectionTab(AppLocalizations l10n, FormSection section) {
    final label = sectionLabel(l10n, section);
    if (!_record.isFilled(section)) return Tab(text: label);
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }

  Widget _qualityButton(AppLocalizations l10n) {
    final count = _record.qualityNotes().length;
    return IconButton(
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: const Color(0xFFE65100),
        child: const Icon(Icons.fact_check_outlined),
      ),
      tooltip: l10n.qualityTitle,
      onPressed: () async {
        final section = await showQualitySheet(context, _record);
        if (section != null && mounted) _tabController.animateTo(section.index);
      },
    );
  }

  Future<void> _fillFromOther() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final filled = await fillFromOther(context, _record, ref.read(btkProvider));
    if (filled == null || !mounted) return;
    if (filled == 0) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.nothingFilled)));
      return;
    }
    setState(() => _generation++);
    _update(_record);
    messenger.showSnackBar(SnackBar(content: Text(l10n.filledCount(filled))));
  }

  Future<void> _saveTemplate() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await saveAsTemplate(context, _record)) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.recordTemplateSaved)));
    } catch (_) {
      AppMessenger.showError((l10n) => l10n.templateSaveFailed);
    }
  }

  Future<void> _revert() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.revertChanges),
        content: Text(l10n.revertMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dCtx, true),
              child: Text(l10n.revertAction)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _record = BtkRecord.fromJson(jsonDecode(_opened) as Map<String, dynamic>);
      _generation++;
    });
    _update(_record);
  }

  Widget _buildTabView() {
    final g = _generation;
    return TabBarView(
      controller: _tabController,
      children: [
        BasicInfoSection(key: ValueKey('basic$g'), record: _record, onChanged: _update, onDetectGps: _detectGps),
        PhysicalGeoSection(key: ValueKey('physGeo$g'), record: _record, onChanged: _update),
        VegetationSection(key: ValueKey('vegetation$g'), record: _record, onChanged: _update),
        SoilSection(key: ValueKey('soil$g'), record: _record, onChanged: _update),
        GeomassSection(key: ValueKey('geomass$g'), record: _record, onChanged: _update),
        VerticalStructureSection(key: ValueKey('vertStruct$g'), record: _record, onChanged: _update),
        if (!kIsWeb) PhotosSection(recordId: _record.id),
      ],
    );
  }
}

// ─── Split view (resizable) ───────────────────────────────────────────────────

class _SplitView extends StatefulWidget {
  final Widget form;
  final VoidCallback onClose;

  const _SplitView({required this.form, required this.onClose});

  @override
  State<_SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<_SplitView> {
  // Wide layout: fraction of width given to the form (left panel)
  double _wideFormFraction = 0.5;

  // Narrow layout: fraction of screen height the PDF panel occupies
  double _narrowHeightFraction = 0.62;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;
    return isWide ? _buildWide(size) : _buildNarrow(size);
  }

  // ── Wide: horizontal split with draggable divider ──────────────────────────
  Widget _buildWide(Size size) {
    final formFlex   = (_wideFormFraction * 1000).round().clamp(250, 750);
    final pdfFlex    = (1000 - formFlex).clamp(250, 750);

    return Row(
      children: [
        Flexible(flex: formFlex, child: widget.form),
        // Draggable divider
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) {
            setState(() {
              _wideFormFraction =
                  (_wideFormFraction + d.delta.dx / size.width).clamp(0.25, 0.75);
            });
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: Container(
              width: 10,
              color: Colors.grey.shade300,
              child: Center(
                child: Container(
                  width: 3,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
        Flexible(flex: pdfFlex, child: const PdfViewerScreen(embedded: true)),
      ],
    );
  }

  // ── Narrow: full-width bottom panel with drag-to-resize ────────────────────
  Widget _buildNarrow(Size size) {
    final l10n = AppLocalizations.of(context)!;
    final panelH = size.height * _narrowHeightFraction;

    return Stack(
      children: [
        widget.form,
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: panelH,
          child: Material(
            elevation: 10,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // ── Header / drag area ───────────────────────────────────
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (d) {
                    setState(() {
                      _narrowHeightFraction =
                          (_narrowHeightFraction - d.delta.dy / size.height)
                              .clamp(0.28, 0.95);
                    });
                  },
                  child: Container(
                    color: Theme.of(context).colorScheme.primary,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag pill
                        const SizedBox(height: 6),
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Title row
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 6, 0, 6),
                              child: Text(
                                AppLocalizations.of(context)!.methodology,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                            ),
                            const Spacer(),
                            // Quick-size buttons
                            _HeaderBtn(
                              icon: Icons.expand_less,
                              tooltip: l10n.zoomIn,
                              onTap: () => setState(() {
                                _narrowHeightFraction =
                                    (_narrowHeightFraction + 0.15)
                                        .clamp(0.28, 0.95);
                              }),
                            ),
                            _HeaderBtn(
                              icon: Icons.expand_more,
                              tooltip: l10n.zoomOut,
                              onTap: () => setState(() {
                                _narrowHeightFraction =
                                    (_narrowHeightFraction - 0.15)
                                        .clamp(0.28, 0.95);
                              }),
                            ),
                            _HeaderBtn(
                              icon: Icons.fullscreen,
                              tooltip: l10n.fullScreen,
                              onTap: () =>
                                  setState(() => _narrowHeightFraction = 0.94),
                            ),
                            _HeaderBtn(
                              icon: Icons.close,
                              tooltip: l10n.close,
                              onTap: widget.onClose,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // ── PDF content ──────────────────────────────────────────
                const Expanded(child: PdfViewerScreen(embedded: true)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        constraints: const BoxConstraints(),
      );
}
