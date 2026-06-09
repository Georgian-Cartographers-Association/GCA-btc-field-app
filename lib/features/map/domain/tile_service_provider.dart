import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../models/tile_service.dart';

const _prefServices = 'tile_services';
const _prefCustomTemplates = 'custom_tile_templates';

class TileServiceNotifier extends StateNotifier<List<TileService>> {
  TileServiceNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefServices);
    if (raw != null) {
      state = (jsonDecode(raw) as List)
          .map((e) => TileService.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefServices, jsonEncode(state.map((s) => s.toJson()).toList()));
  }

  Future<void> add(TileService svc) async {
    state = [...state, svc];
    await _persist();
  }

  Future<void> addFromTemplate(Map<String, dynamic> tpl, String name) async {
    final svc = TileService(
      id: const Uuid().v4().substring(0, 8),
      name: name.isNotEmpty ? name : tpl['name'] as String,
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == (tpl['serviceType'] as String? ?? 'xyz'),
        orElse: () => ServiceType.xyz,
      ),
      urlTemplate: tpl['urlTemplate'] as String,
      subdomains: List<String>.from(tpl['subdomains'] as List? ?? []),
      wmsLayers: tpl['wmsLayers'] as String? ?? '',
    );
    await add(svc);
  }

  Future<void> update(TileService svc) async {
    state = [for (final s in state) if (s.id == svc.id) svc else s];
    await _persist();
  }

  Future<void> toggleVisible(String id) async {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(visible: !s.visible) else s
    ];
    await _persist();
  }

  Future<void> setOpacity(String id, double opacity) async {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(opacity: opacity) else s
    ];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _persist();
  }

  // ── Custom templates ────────────────────────────────────────────────────────

  /// Save a service as a reusable custom template.
  static Future<void> saveAsTemplate(TileService svc) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefCustomTemplates);
    final list = raw != null
        ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    // Replace if same name already exists
    list.removeWhere((t) => t['name'] == svc.name);
    list.add({
      'name': svc.name,
      'urlTemplate': svc.urlTemplate,
      'subdomains': svc.subdomains,
      'wmsLayers': svc.wmsLayers,
      'serviceType': svc.serviceType.name,
      'isCustom': true,
    });
    await prefs.setString(_prefCustomTemplates, jsonEncode(list));
  }

  /// Load all templates: built-in + user-saved.
  static Future<List<Map<String, dynamic>>> loadAllTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefCustomTemplates);
    final custom = raw != null
        ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    return [...TileService.kBuiltinTemplates, ...custom];
  }

  /// Delete a custom template by name.
  static Future<void> removeCustomTemplate(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefCustomTemplates);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    list.removeWhere((t) => t['name'] == name);
    await prefs.setString(_prefCustomTemplates, jsonEncode(list));
  }
}

final tileServiceProvider =
    StateNotifierProvider<TileServiceNotifier, List<TileService>>(
        (ref) => TileServiceNotifier());
