import 'package:btk_field_app/features/settings/ui/tips_section.dart';
import 'package:btk_field_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tips stay folded until opened', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: TipsSection()),
    ));
    expect(find.text('Tips'), findsOneWidget);
    expect(find.text('Fill in by voice'), findsNothing);

    await tester.tap(find.text('Tips'));
    await tester.pumpAndSettle();
    expect(find.text('Fill in by voice'), findsOneWidget);
    expect(find.textContaining('Gboard'), findsOneWidget);
  });
}
