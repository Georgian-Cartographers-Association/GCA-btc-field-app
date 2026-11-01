import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/btk_record.dart';
import '../../domain/photo_provider.dart';
import '../widgets/section_photo_panel.dart';
import '../../../../l10n/generated/app_localizations.dart';

class SoilSection extends ConsumerStatefulWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;

  const SoilSection({super.key, required this.record, required this.onChanged});

  @override
  ConsumerState<SoilSection> createState() => _SoilSectionState();
}

class _SoilSectionState extends ConsumerState<SoilSection> {
  late final TextEditingController _soilTypeNameCtrl;
  late final TextEditingController _soilProfileDescCtrl;
  late final TextEditingController _geohorizonIndexCtrl;
  late final TextEditingController _soilSurfaceFormationCtrl;
  late List<List<TextEditingController>> _horizonCtrls;

  String get _photoKey => '${widget.record.id}_soil';

  List<TextEditingController> _makeHorizonCtrls(SoilHorizonRow h) => [
        TextEditingController(text: h.horizon),
        TextEditingController(text: h.description),
      ];

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _soilTypeNameCtrl = TextEditingController(text: r.soilTypeName);
    _soilProfileDescCtrl = TextEditingController(text: r.soilProfileDesc);
    _geohorizonIndexCtrl = TextEditingController(text: r.geohorizonIndex);
    _soilSurfaceFormationCtrl =
        TextEditingController(text: r.soilSurfaceFormation);
    _horizonCtrls = r.soilHorizons.map(_makeHorizonCtrls).toList();
  }

  @override
  void dispose() {
    _soilTypeNameCtrl.dispose();
    _soilProfileDescCtrl.dispose();
    _geohorizonIndexCtrl.dispose();
    _soilSurfaceFormationCtrl.dispose();
    for (final row in _horizonCtrls) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _addHorizon() {
    final newH = SoilHorizonRow();
    setState(() {
      widget.record.soilHorizons.add(newH);
      _horizonCtrls.add(_makeHorizonCtrls(newH));
    });
    widget.onChanged(widget.record);
  }

  void _removeHorizon(int i) {
    if (widget.record.soilHorizons.length <= 1) return;
    for (final c in _horizonCtrls[i]) {
      c.dispose();
    }
    setState(() {
      widget.record.soilHorizons.removeAt(i);
      _horizonCtrls.removeAt(i);
    });
    widget.onChanged(widget.record);
  }

  void _upd(BtkRecord r) {
    setState(() {});
    widget.onChanged(r);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = widget.record;
    final photos = ref.watch(photoProvider(_photoKey));
    final notifier = ref.read(photoProvider(_photoKey).notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, l10n.soil),
          const SizedBox(height: 12),
          TextField(
            controller: _soilTypeNameCtrl,
            onChanged: (v) => _upd(r..soilTypeName = v),
            decoration: InputDecoration(
              labelText: l10n.soilTypeName,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _soilProfileDescCtrl,
            onChanged: (v) => _upd(r..soilProfileDesc = v),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.soilProfileDescShort,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          // ── Soil profile photos ─────────────────────────────────────
          SectionPhotoPanel(
            label: l10n.morphDescPhotos,
            photos: photos,
            onCamera: () => notifier.addFromSource(ImageSource.camera, context),
            onGallery: () => notifier.addFromSource(ImageSource.gallery, context),
            onTap: (i) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SectionFullScreenGallery(
                  photos: photos,
                  initialIndex: i,
                  title: l10n.soil,
                ),
              ),
            ),
            onDelete: (photo) => confirmDeleteSectionPhoto(
              context,
              () => notifier.delete(photo),
            ),
          ),

          const SizedBox(height: 16),
          Text(l10n.soilHorizons,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            l10n.soilLegend,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ...List.generate(r.soilHorizons.length, (i) {
            final h = r.soilHorizons[i];
            final cs = _horizonCtrls[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: cs[0],
                      onChanged: (v) => h.horizon = v,
                      decoration: InputDecoration(
                        labelText: l10n.horizonShort,
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: cs[1],
                      onChanged: (v) => h.description = v,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red, size: 18),
                    onPressed: () => _removeHorizon(i),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: _addHorizon,
            icon: const Icon(Icons.add),
            label: Text(l10n.addHorizon),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _geohorizonIndexCtrl,
            onChanged: (v) => _upd(r..geohorizonIndex = v),
            decoration: InputDecoration(
              labelText: l10n.geohorizonIndex,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _soilSurfaceFormationCtrl,
            onChanged: (v) => _upd(r..soilSurfaceFormation = v),
            decoration: InputDecoration(
              labelText: l10n.soilSurfaceFormationShort,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionHeader(BuildContext context, String title) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer)),
    );
