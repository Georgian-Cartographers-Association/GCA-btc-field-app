import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';

class MapLayersState {
  final bool showOsm;
  final bool showTopo;
  final bool showBoundary;
  final bool showRegions;
  final bool showMunicipalities;
  final bool showPoints;

  const MapLayersState({
    this.showOsm = true,
    this.showTopo = false,
    this.showBoundary = true,
    this.showRegions = false,
    this.showMunicipalities = false,
    this.showPoints = true,
  });

  MapLayersState copyWith({
    bool? showOsm,
    bool? showTopo,
    bool? showBoundary,
    bool? showRegions,
    bool? showMunicipalities,
    bool? showPoints,
  }) =>
      MapLayersState(
        showOsm: showOsm ?? this.showOsm,
        showTopo: showTopo ?? this.showTopo,
        showBoundary: showBoundary ?? this.showBoundary,
        showRegions: showRegions ?? this.showRegions,
        showMunicipalities: showMunicipalities ?? this.showMunicipalities,
        showPoints: showPoints ?? this.showPoints,
      );
}

class MapLayersNotifier extends StateNotifier<MapLayersState> {
  MapLayersNotifier() : super(const MapLayersState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = MapLayersState(
      showOsm: prefs.getBool(AppConstants.prefShowOsm) ?? true,
      showTopo: prefs.getBool(AppConstants.prefShowTopo) ?? false,
      showBoundary: prefs.getBool(AppConstants.prefShowBoundary) ?? true,
      showRegions: prefs.getBool(AppConstants.prefShowRegions) ?? false,
      showMunicipalities:
          prefs.getBool(AppConstants.prefShowMunicipalities) ?? false,
      showPoints: prefs.getBool(AppConstants.prefShowPoints) ?? true,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefShowOsm, state.showOsm);
    await prefs.setBool(AppConstants.prefShowTopo, state.showTopo);
    await prefs.setBool(AppConstants.prefShowBoundary, state.showBoundary);
    await prefs.setBool(AppConstants.prefShowRegions, state.showRegions);
    await prefs.setBool(
        AppConstants.prefShowMunicipalities, state.showMunicipalities);
    await prefs.setBool(AppConstants.prefShowPoints, state.showPoints);
  }

  Future<void> toggleOsm() async {
    state = state.copyWith(showOsm: !state.showOsm);
    await _persist();
  }

  Future<void> toggleTopo() async {
    state = state.copyWith(showTopo: !state.showTopo);
    await _persist();
  }

  Future<void> toggleBoundary() async {
    state = state.copyWith(showBoundary: !state.showBoundary);
    await _persist();
  }

  Future<void> toggleRegions() async {
    state = state.copyWith(showRegions: !state.showRegions);
    await _persist();
  }

  Future<void> toggleMunicipalities() async {
    state = state.copyWith(showMunicipalities: !state.showMunicipalities);
    await _persist();
  }

  Future<void> togglePoints() async {
    state = state.copyWith(showPoints: !state.showPoints);
    await _persist();
  }
}

final mapLayersProvider =
    StateNotifierProvider<MapLayersNotifier, MapLayersState>(
        (ref) => MapLayersNotifier());
