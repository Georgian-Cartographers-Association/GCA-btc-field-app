import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/btk_record.dart';
import '../../domain/photo_provider.dart';
import '../widgets/section_photo_panel.dart';

class VerticalStructureSection extends ConsumerStatefulWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;

  const VerticalStructureSection(
      {super.key, required this.record, required this.onChanged});

  @override
  ConsumerState<VerticalStructureSection> createState() =>
      _VerticalStructureSectionState();
}

class _VerticalStructureSectionState
    extends ConsumerState<VerticalStructureSection> {
  late final TextEditingController _typeNameCtrl;
  late final TextEditingController _indexCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _descCtrl;

  String get _photoKey => '${widget.record.id}_vertStruct';

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _typeNameCtrl = TextEditingController(text: r.vertStructTypeName);
    _indexCtrl = TextEditingController(text: r.vertStructIndex);
    _heightCtrl = TextEditingController(text: r.vertStructHeight);
    _descCtrl = TextEditingController(text: r.vertStructDesc);
  }

  @override
  void dispose() {
    _typeNameCtrl.dispose();
    _indexCtrl.dispose();
    _heightCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final photos = ref.watch(photoProvider(_photoKey));
    final notifier = ref.read(photoProvider(_photoKey).notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _vsHeader(context, 'ბტკ-ის ვერტიკალური სტრუქტურა'),
          const SizedBox(height: 16),
          TextField(
            controller: _typeNameCtrl,
            onChanged: (v) => widget.onChanged(r..vertStructTypeName = v),
            decoration: const InputDecoration(
              labelText: 'ვ.ს. ტიპის სახელწოდება',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _indexCtrl,
                  onChanged: (v) => widget.onChanged(r..vertStructIndex = v),
                  decoration: const InputDecoration(
                    labelText: 'ინდექსი',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _heightCtrl,
                  onChanged: (v) => widget.onChanged(r..vertStructHeight = v),
                  decoration: const InputDecoration(
                    labelText: 'სიმაღლე',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            onChanged: (v) => widget.onChanged(r..vertStructDesc = v),
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'ვ.პ. მიწისზედა ნ. დამოკიდ. მიწისქვედა ნ.თ.',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          // ── Vert-struct photos ──────────────────────────────────────
          SectionPhotoPanel(
            label: 'ვ.ს. ფოტოები',
            photos: photos,
            onCamera: () => notifier.addFromSource(ImageSource.camera, context),
            onGallery: () => notifier.addFromSource(ImageSource.gallery, context),
            onTap: (i) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SectionFullScreenGallery(
                  photos: photos,
                  initialIndex: i,
                  title: 'ვ.სტრ.',
                ),
              ),
            ),
            onDelete: (photo) => confirmDeleteSectionPhoto(
              context,
              () => notifier.delete(photo),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _vsHeader(BuildContext context, String title) => Container(
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
