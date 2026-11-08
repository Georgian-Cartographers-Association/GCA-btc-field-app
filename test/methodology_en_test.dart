import 'dart:convert';

import 'package:btk_field_app/core/constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the English methodology is bundled, apart from the Georgian one',
      () async {
    final en = await rootBundle.load(AppConstants.pdfAssetPathEn);
    final ka = await rootBundle.load(AppConstants.pdfAssetPath);
    final head = ascii.decode(en.buffer.asUint8List(0, 5));
    expect(head, '%PDF-');
    expect(en.lengthInBytes, isNot(ka.lengthInBytes));
  });
}
