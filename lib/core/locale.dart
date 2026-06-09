import 'package:flutter/material.dart';

enum AppLocale {
  ka,
  en;

  Locale get locale => Locale(name);

  String get displayName => switch (this) {
        AppLocale.ka => 'ქართული',
        AppLocale.en => 'English',
      };

  static AppLocale fromCode(String code) =>
      values.firstWhere((l) => l.name == code, orElse: () => ka);

  static AppLocale fromLocale(Locale locale) =>
      fromCode(locale.languageCode);
}
