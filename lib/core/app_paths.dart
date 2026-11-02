import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Moves a saved path into [documentsDir]. iOS changes the app's container
/// folder on updates and reinstalls, so a saved full path stops being valid
/// while the file itself stays in Documents.
String rebaseToDocuments(String saved, String documentsDir) {
  const marker = '/Documents/';
  final at = saved.indexOf(marker);
  if (at < 0) return saved;
  return '$documentsDir${saved.substring(at + marker.length - 1)}';
}

/// The folder to rebase saved paths to, or null where paths stay valid.
Future<String?> documentsDirToRebase() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return null;
  return (await getApplicationDocumentsDirectory()).path;
}
