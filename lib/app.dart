import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/settings/domain/settings_provider.dart';
import 'l10n/generated/app_localizations.dart';
import 'router.dart';

class BtkApp extends ConsumerWidget {
  const BtkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final geoTextTheme = GoogleFonts.notoSansGeorgianTextTheme();

    return MaterialApp.router(
      title: 'BTC Field App',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [Locale('ka'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: FlexThemeData.light(
        scheme: FlexScheme.green,
        textTheme: geoTextTheme,
        useMaterial3: true,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.green,
        textTheme:
            GoogleFonts.notoSansGeorgianTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
    );
  }
}
