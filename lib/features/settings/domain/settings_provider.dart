import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../core/locale.dart';

/// Where BTK records are persisted.
enum StorageMode {
  local, // SQLite (Android) / SharedPreferences (web) — default
  cloud, // Firestore personal — requires Firebase Auth
  expedition, // Firestore shared expedition — requires Firebase Auth + expId
}


/// Coordinate format used when exporting CSV / GeoJSON.
enum ExportCoordFormat { dd, dm, dms, utm38 }
class SettingsState {
  final ThemeMode themeMode;
  final AppLocale appLocale;
  final List<String> emails;
  final int pdfPage;
  final bool screenAwake; // keep screen on while map is open
  final StorageMode storageMode;
  final String? expeditionId; // non-null only when storageMode == expedition
  final ExportCoordFormat exportCoordFormat;

  Locale get locale => appLocale.locale;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.appLocale = AppLocale.ka,
    this.emails = const [],
    this.pdfPage = 0,
    this.screenAwake = false,
    this.storageMode = StorageMode.local,
    this.expeditionId,
    this.exportCoordFormat = ExportCoordFormat.dd,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppLocale? appLocale,
    List<String>? emails,
    int? pdfPage,
    bool? screenAwake,
    StorageMode? storageMode,
    Object? expeditionId = _sentinel,
    ExportCoordFormat? exportCoordFormat,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        appLocale: appLocale ?? this.appLocale,
        emails: emails ?? this.emails,
        pdfPage: pdfPage ?? this.pdfPage,
        screenAwake: screenAwake ?? this.screenAwake,
        storageMode: storageMode ?? this.storageMode,
        expeditionId: expeditionId == _sentinel
            ? this.expeditionId
            : expeditionId as String?,
        exportCoordFormat: exportCoordFormat ?? this.exportCoordFormat,
      );
}

const Object _sentinel = Object();

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(AppConstants.prefTheme) ?? 'system';
    final localeStr = prefs.getString(AppConstants.prefLocale) ?? 'ka';
    final pdfPage = prefs.getInt(AppConstants.prefPdfPage) ?? 0;
    final screenAwake = prefs.getBool('screen_awake') ?? false;
    final storageModeStr = prefs.getString('storage_mode') ?? 'local';
    final expeditionId = prefs.getString('expedition_id');
    final coordFmtStr = prefs.getString('export_coord_format') ?? 'dd';

    List<String> emails = [];
    final emailsJson = prefs.getString(AppConstants.prefEmails);
    if (emailsJson != null) {
      emails = List<String>.from(jsonDecode(emailsJson) as List);
    } else {
      final old = prefs.getString(AppConstants.prefEmail) ?? '';
      if (old.isNotEmpty) emails = [old];
    }

    state = SettingsState(
      themeMode: _parseTheme(themeStr),
      appLocale: AppLocale.fromCode(localeStr),
      emails: emails,
      pdfPage: pdfPage,
      screenAwake: screenAwake,
      storageMode: _parseStorageMode(storageModeStr),
      expeditionId: expeditionId,
      exportCoordFormat: _parseCoordFormat(coordFmtStr),
    );
  }

  static StorageMode _parseStorageMode(String s) => switch (s) {
        'cloud' => StorageMode.cloud,
        'expedition' => StorageMode.expedition,
        _ => StorageMode.local,
      };

  static String _storageModeStr(StorageMode m) => switch (m) {
        StorageMode.cloud => 'cloud',
        StorageMode.expedition => 'expedition',
        StorageMode.local => 'local',
      };

  static ThemeMode _parseTheme(String s) => switch (s) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };

  static String _themeStr(ThemeMode m) => switch (m) {
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
        _ => 'light',
      };

  Future<void> _persistEmails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefEmails, jsonEncode(state.emails));
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefTheme, _themeStr(mode));
  }

  Future<void> setScreenAwake(bool value) async {
    state = state.copyWith(screenAwake: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('screen_awake', value);
  }

  Future<void> setLocale(AppLocale locale) async {
    state = state.copyWith(appLocale: locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLocale, locale.name);
  }

  Future<void> addEmail(String email) async {
    final e = email.trim();
    if (e.isEmpty || state.emails.contains(e)) return;
    state = state.copyWith(emails: [...state.emails, e]);
    await _persistEmails();
  }

  Future<void> removeEmail(String email) async {
    state = state.copyWith(
        emails: state.emails.where((e) => e != email).toList());
    await _persistEmails();
  }

  Future<void> savePdfPage(int page) async {
    state = state.copyWith(pdfPage: page);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefPdfPage, page);
  }

  Future<void> setStorageMode(StorageMode mode) async {
    state = state.copyWith(storageMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_mode', _storageModeStr(mode));
  }

  Future<void> joinExpedition(String expeditionId) async {
    state = state.copyWith(
      storageMode: StorageMode.expedition,
      expeditionId: expeditionId,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_mode', 'expedition');
    await prefs.setString('expedition_id', expeditionId);
  }

  Future<void> leaveExpedition() async {
    state = state.copyWith(
      storageMode: StorageMode.cloud,
      expeditionId: null,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_mode', 'cloud');
    await prefs.remove('expedition_id');
  }

  static ExportCoordFormat _parseCoordFormat(String s) => switch (s) {
        'dm' => ExportCoordFormat.dm,
        'dms' => ExportCoordFormat.dms,
        'utm38' => ExportCoordFormat.utm38,
        _ => ExportCoordFormat.dd,
      };

  Future<void> setExportCoordFormat(ExportCoordFormat fmt) async {
    state = state.copyWith(exportCoordFormat: fmt);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('export_coord_format', fmt.name);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
        (ref) => SettingsNotifier());
