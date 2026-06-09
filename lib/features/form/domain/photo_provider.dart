import 'dart:io';
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

  Future<void> addFromSource(ImageSource source) async {
    final XFile? file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (file == null) return;

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/photos/$recordId');
    await dir.create(recursive: true);

    final ext = file.path.split('.').last.toLowerCase();
    final id = const Uuid().v4().substring(0, 8);
    final dest = '${dir.path}/$id.$ext';
    await File(file.path).copy(dest);

    final photo = Photo(
      id: id,
      recordId: recordId,
      filePath: dest,
      sortOrder: state.length,
      createdAt: DateTime.now(),
    );
    await BtkDatabase.insertPhoto(photo);
    state = [...state, photo];
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
