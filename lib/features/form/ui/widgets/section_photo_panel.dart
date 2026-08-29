import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../models/photo.dart';

/// Reusable inline photo panel for form sections.
/// Shows camera / gallery buttons and a horizontal thumbnail strip.
class SectionPhotoPanel extends StatelessWidget {
  final String label;
  final List<Photo> photos;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ValueChanged<int> onTap;
  final ValueChanged<Photo> onDelete;

  const SectionPhotoPanel({
    super.key,
    required this.label,
    required this.photos,
    required this.onCamera,
    required this.onGallery,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_outlined, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _IconChip(
                icon: Icons.camera_alt_outlined,
                label: 'კამერა',
                onTap: onCamera,
              ),
              const SizedBox(width: 6),
              _IconChip(
                icon: Icons.photo_library_outlined,
                label: 'გალერეა',
                onTap: onGallery,
              ),
            ],
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) => _Thumb(
                  photo: photos[i],
                  onTap: () => onTap(i),
                  onDelete: () => onDelete(photos[i]),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'ფოტო არ არის. გადაიღეთ კამერით ან მიაბით გალერეიდან.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IconChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.onPrimaryContainer),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _Thumb({required this.photo, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(photo.filePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen swipeable gallery for section photos.
class SectionFullScreenGallery extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;
  final String title;

  const SectionFullScreenGallery({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.title = 'ფოტო',
  });

  @override
  State<SectionFullScreenGallery> createState() =>
      _SectionFullScreenGalleryState();
}

class _SectionFullScreenGalleryState extends State<SectionFullScreenGallery> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${widget.title}  ${_current + 1}/${widget.photos.length}'),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: Image.file(
              File(widget.photos[i].filePath),
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper to pick and confirm deletion of a photo from any section.
Future<void> confirmDeleteSectionPhoto(
    BuildContext context, VoidCallback onConfirm) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dCtx) => AlertDialog(
      title: const Text('ფოტოს წაშლა'),
      content: const Text('გსურთ ამ ფოტოს წაშლა?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dCtx, false),
          child: const Text('გაუქმება'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(dCtx, true),
          child: const Text('წაშლა', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  if (ok == true) onConfirm();
}
