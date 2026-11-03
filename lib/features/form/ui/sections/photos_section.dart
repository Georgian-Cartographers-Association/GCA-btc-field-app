import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/photo.dart';
import '../../domain/photo_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Photo gallery section — shown as the last tab in BtkFormScreen.
/// Android-only: web shows a placeholder.
class PhotosSection extends ConsumerWidget {
  final String recordId;
  const PhotosSection({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final photos = ref.watch(photoProvider(recordId));
    final soil = ref.watch(photoProvider('${recordId}_soil'));
    final vertStruct = ref.watch(photoProvider('${recordId}_vertStruct'));
    final notifier = ref.read(photoProvider(recordId).notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Action buttons ────────────────────────────────────────────
          Row(
            children: [
              FilledButton.icon(
                onPressed: () => notifier.addFromSource(ImageSource.camera, context),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: Text(l10n.camera),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => notifier.addFromSource(ImageSource.gallery, context),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(l10n.gallery),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Grids, one per place the photos were taken from ──────────
          if (photos.isEmpty && soil.isEmpty && vertStruct.isEmpty)
            const _EmptyHint()
          else ...[
            _group(context, ref, l10n.photosGeneral, recordId, photos),
            _group(context, ref, l10n.soil, '${recordId}_soil', soil),
            _group(context, ref, l10n.tabVertStruct, '${recordId}_vertStruct', vertStruct),
          ],
        ],
      ),
    );
  }

  Widget _group(BuildContext context, WidgetRef ref, String title, String key,
      List<Photo> photos) {
    if (photos.isEmpty) return const SizedBox.shrink();
    final notifier = ref.read(photoProvider(key).notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('$title (${photos.length})',
                style: Theme.of(context).textTheme.titleSmall),
          ),
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
              onTap: () => _openGallery(context, key, i),
              onDelete: () => _confirmDelete(context, notifier, photos[i]),
            ),
          ),
        ],
      ),
    );
  }

  void _openGallery(BuildContext ctx, String photosKey, int index) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) =>
            _FullScreenGallery(photosKey: photosKey, initialIndex: index),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext ctx, PhotoNotifier notifier, Photo photo) async {
    final l10n = AppLocalizations.of(ctx)!;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.deletePhoto),
        content: Text(l10n.deletePhotoConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(l10n.delete,
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
          if (photo.caption.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
                padding: const EdgeInsets.all(3),
                child: Text(
                  photo.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.noPhotoAdded,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.cameraOrGallery,
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

class _FullScreenGallery extends ConsumerStatefulWidget {
  final String photosKey;
  final int initialIndex;

  const _FullScreenGallery(
      {required this.photosKey, required this.initialIndex});

  @override
  ConsumerState<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends ConsumerState<_FullScreenGallery> {
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

  Future<void> _editCaption(Photo photo) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(photoProvider(widget.photosKey).notifier);
    final ctrl = TextEditingController(text: photo.caption);
    final caption = await showDialog<String>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.photoCaption),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx), child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dCtx, ctrl.text.trim()),
              child: Text(l10n.save)),
        ],
      ),
    );
    ctrl.dispose();
    if (caption == null) return;
    try {
      await notifier.setCaption(photo, caption);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.photoCaptionFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photos = ref.watch(photoProvider(widget.photosKey));
    final hasCurrent = _current < photos.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${photos.length}'),
        actions: [
          if (hasCurrent)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: l10n.photoCaption,
              onPressed: () => _editCaption(photos[_current]),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: Image.file(
                    File(photos[i].filePath),
                    errorBuilder: (context, err, stack) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hasCurrent && photos[_current].caption.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(photos[_current].caption,
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
