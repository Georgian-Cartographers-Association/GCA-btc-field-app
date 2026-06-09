import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../models/raster_layer.dart';

const _prefDeviceRasters = 'device_rasters';
const _prefRasterVis = 'raster_vis_';
const _prefRasterOpa = 'raster_opa_';

class RasterNotifier extends StateNotifier<List<RasterLayer>> {
  RasterNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final raw = await rootBundle.loadString('assets/rasters/catalog.json');
      final catalog = jsonDecode(raw) as Map<String, dynamic>;
      final assetLayers = (catalog['rasters'] as List)
          .map((e) => RasterLayer.fromCatalog(e as Map<String, dynamic>))
          .toList();

      for (final r in assetLayers) {
        final v = prefs.getBool('$_prefRasterVis${r.id}');
        final o = prefs.getDouble('$_prefRasterOpa${r.id}');
        if (v != null) r.visible = v;
        if (o != null) r.opacity = o;
      }

      final deviceRaw = prefs.getString(_prefDeviceRasters);
      final deviceLayers = <RasterLayer>[];
      if (deviceRaw != null) {
        final list =
            (jsonDecode(deviceRaw) as List).cast<Map<String, dynamic>>();
        for (final j in list) {
          final r = RasterLayer.fromJson(j);
          final v = prefs.getBool('$_prefRasterVis${r.id}');
          final o = prefs.getDouble('$_prefRasterOpa${r.id}');
          if (v != null) r.visible = v;
          if (o != null) r.opacity = o;
          deviceLayers.add(r);
        }
      }

      state = [...assetLayers, ...deviceLayers];
    } catch (_) {
      state = [];
    }
  }

  Future<void> _persistDeviceRasters() async {
    final prefs = await SharedPreferences.getInstance();
    final device = state.where((r) => r.isDeviceLayer).toList();
    await prefs.setString(
        _prefDeviceRasters, jsonEncode(device.map((r) => r.toJson()).toList()));
  }

  Future<void> addFromFile({
    required String name,
    required double north,
    required double south,
    required double east,
    required double west,
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    final layer = RasterLayer(
      id: const Uuid().v4().substring(0, 8),
      name: name,
      filePath: filePath,
      fileBytes: fileBytes,
      northLat: north,
      southLat: south,
      eastLon: east,
      westLon: west,
      opacity: 0.85,
      visible: true,
    );
    state = [...state, layer];
    if (!kIsWeb) await _persistDeviceRasters();
  }

  Future<void> removeDevice(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _persistDeviceRasters();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefRasterVis$id');
    await prefs.remove('$_prefRasterOpa$id');
  }

  Future<void> toggleVisible(String id) async {
    state = [
      for (final l in state)
        if (l.id == id)
          RasterLayer(
            id: l.id,
            name: l.name,
            assetPath: l.assetPath,
            filePath: l.filePath,
            fileBytes: l.fileBytes,
            northLat: l.northLat,
            southLat: l.southLat,
            eastLon: l.eastLon,
            westLon: l.westLon,
            opacity: l.opacity,
            visible: !l.visible,
          )
        else
          l
    ];
    final prefs = await SharedPreferences.getInstance();
    final layer = state.firstWhere((l) => l.id == id);
    await prefs.setBool('$_prefRasterVis$id', layer.visible);
  }

  Future<void> setOpacity(String id, double opacity) async {
    state = [
      for (final l in state)
        if (l.id == id)
          RasterLayer(
            id: l.id,
            name: l.name,
            assetPath: l.assetPath,
            filePath: l.filePath,
            fileBytes: l.fileBytes,
            northLat: l.northLat,
            southLat: l.southLat,
            eastLon: l.eastLon,
            westLon: l.westLon,
            opacity: opacity,
            visible: l.visible,
          )
        else
          l
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_prefRasterOpa$id', opacity);
  }
}

final rasterProvider =
    StateNotifierProvider<RasterNotifier, List<RasterLayer>>(
        (ref) => RasterNotifier());
