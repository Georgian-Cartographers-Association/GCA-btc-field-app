import 'dart:async';
import 'dart:typed_data';

import 'package:btk_field_app/features/pdf/ui/pdf_preview_screen.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:btk_field_app/models/btk_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final record = BtkRecord(id: 'AB12CD34', date: DateTime(2026, 11, 2));

  Widget app(Future<Uint8List> Function(List<BtkRecord>) buildPdf) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PdfPreviewScreen(records: [record], buildPdf: buildPdf),
      );

  testWidgets('offers no share or save while the PDF is being built', (tester) async {
    final pending = Completer<Uint8List>();
    await tester.pumpWidget(app((_) => pending.future));
    await tester.pump();

    expect(find.text('Preparing PDF...'), findsOneWidget);
    expect(find.text('Share'), findsNothing);
    expect(find.text('Save as file'), findsNothing);
  });

  testWidgets('a failed build offers a retry, which builds again', (tester) async {
    var calls = 0;
    await tester.pumpWidget(app((_) async {
      calls++;
      throw StateError('no PDF');
    }));
    await tester.pump();

    expect(find.text('Could not create the PDF'), findsOneWidget);
    expect(find.text('Share'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(calls, 2);
  });
}
