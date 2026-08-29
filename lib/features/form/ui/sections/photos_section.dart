import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/photo.dart';
import '../../domain/photo_provider.dart';

/// Photo gallery section — shown as the last tab in BtkFormScreen.
/// Android-only: web shows a placeholder.
class PhotosSection extends ConsumerWidget {
  final String recordId;
  const PhotosSection({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(photoProvider(recordId));
    final notifier = ref.read(photoProvider(recordId).notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Action buttons ────────────────────────────────────────────
          Row(
            children: [
              FilledButton.icon(
                onPressed: () => notifier.addFromSource(ImageSource.camera, context),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('კამერა'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => notifier.addFromSource(ImageSource.gallery, context),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('გალერეა'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Grid ─────────────────────────────────────────────────────
          if (photos.isEmpty)
            const _EmptyHint()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: photos.length,
              itemBuilder: (context, i) => _PhotoTile(
                photo: photos[i],
                onTap: () => _openGallery(context, photos, i),
                onDelete: () => _confirmDelete(context, notifier, photos[i]),
              ),
            ),
        ],
      ),
    );
  }

  void _openGallery(BuildContext ctx, List<Photo> photos, int index) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) =>
            _FullScreenGallery(photos: photos, initialIndex: index),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext ctx, PhotoNotifier notifier, Photo photo) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('ფოტოს წაშლა'),
        content: const Text('გსურთ ამ ფოტოს წაშლა?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('გაუქმება')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('წაშლა',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) await notifier.delete(photo);
  }
}

// ── Photo tile ───────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PhotoTile(
      {required this.photo, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(photo.filePath),
            fit: BoxFit.cover,
            errorBuilder: (context, err, stack) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined,
                  color: Colors.grey),
            ),
          ),
          // Delete button (top-right)
          Positioned(
            top: 3,
            right: 3,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty hint ───────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.photo_camera_outlined,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'ფოტო არ არის დამატებული',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'კამერა ან გალერეა',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full-screen swipeable gallery ────────────────────────────────────────────

class _FullScreenGallery extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;

  const _FullScreenGallery(
      {required this.photos, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
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
        title: Text('${_current + 1} / ${widget.photos.length}'),
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
              errorBuilder: (context, err, stack) => const Icon(
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
