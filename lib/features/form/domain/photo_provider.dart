import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../database/btk_database.dart';
import '../../../models/photo.dart';

class PhotoNotifier extends StateNotifier<List<Photo>> {
  PhotoNotifier(this.recordId) : super([]) {
    _load();
  }

  final String recordId;

  Future<void> _load() async {
    state = await BtkDatabase.getPhotos(recordId);
  }

  Future<void> addFromSource(ImageSource source, BuildContext context) async {
    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ფოტო ვერ გაიხსნა: $e')),
        );
      }
      return;
    }
    if (file == null) return;

    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/photos/$recordId');
      await dir.create(recursive: true);

      final ext = file.path.split('.').last.toLowerCase();
      final id = const Uuid().v4().substring(0, 8);
      final dest = '${dir.path}/$id.$ext';

      // Use readAsBytes instead of File.copy — works with content URIs (Android 14+)
      final bytes = await file.readAsBytes();
      await File(dest).writeAsBytes(bytes);

      final photo = Photo(
        id: id,
        recordId: recordId,
        filePath: dest,
        sortOrder: state.length,
        createdAt: DateTime.now(),
      );
      await BtkDatabase.insertPhoto(photo);
      state = [...state, photo];
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ფოტო ვერ შეინახა: $e')),
        );
      }
    }
  }

  Future<void> delete(Photo photo) async {
    await BtkDatabase.deletePhoto(photo.id);
    try {
      await File(photo.filePath).delete();
    } catch (_) {}
    state = state.where((p) => p.id != photo.id).toList();
  }
}

final photoProvider =
    StateNotifierProvider.family<PhotoNotifier, List<Photo>, String>(
  (ref, recordId) => PhotoNotifier(recordId),
);
