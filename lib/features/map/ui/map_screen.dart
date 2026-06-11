import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants.dart';
import '../../../models/raster_layer.dart';
import '../../../models/tile_service.dart';
import '../../records/domain/btk_provider.dart';
import '../domain/map_provider.dart';
import '../../raster/domain/raster_provider.dart';
import '../domain/tile_service_provider.dart';
import '../../../utils/measurement_service.dart';
import 'widgets/layer_control_panel.dart';
import 'widgets/map_search_sheet.dart';
import 'widgets/measurement_layers.dart';
import 'widgets/measurement_panel.dart';
import 'widgets/weather_panel.dart';
import '../../../models/gps_track.dart';
import '../../gps/domain/gps_track_provider.dart';
import '../../settings/domain/settings_provider.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/export_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  bool _addingPoint = false;

  // Tile cache: starts in-memory, switches to FileCacheStore once app dir resolves
  CacheStore _cacheStore = MemCacheStore();

  // Compass heading (live) — null until magnetometer fires first event
  double? _compassHeading;

  // GeoJSON boundaries
  List<List<LatLng>> _boundaryPolygons = [];
  List<List<LatLng>> _regionPolygons = [];
  List<List<LatLng>> _municipalityPolygons = [];

  // Search index (built from local GeoJSON at startup)
  List<GeoSearchResult> _searchIndex = [];

  // Measurement
  MeasureMode _measureMode = MeasureMode.none;
  List<LatLng> _measurePoints = [];

  @override
  void initState() {
    super.initState();
    _loadGeojson(AppConstants.geojsonAssetPath, (p) => _boundaryPolygons = p);
    _loadGeojson(AppConstants.regionsGeojsonPath, (p) => _regionPolygons = p);
    _loadGeojson(AppConstants.municipalitiesGeojsonPath,
        (p) => _municipalityPolygons = p);
    _buildSearchIndex();
    if (!kIsWeb) {
      _initCompass();
      _initTileCache();
    }
  }

  Future<void> _initTileCache() async {
    final dir = await getApplicationCacheDirectory();
    if (mounted) {
      setState(() {
        _cacheStore = FileCacheStore('${dir.path}/tile_cache');
      });
    }
  }

  void _initCompass() {
    FlutterCompass.events?.listen((event) {
      if (mounted && event.heading != null) {
        setState(() => _compassHeading = event.heading);
      }
    });
  }

  Future<void> _loadGeojson(
      String assetPath, void Function(List<List<LatLng>>) setter) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final geo = jsonDecode(raw) as Map<String, dynamic>;
      final features = geo['features'] as List<dynamic>;
      final polys = <List<LatLng>>[];
      for (final f in features) {
        final geom = f['geometry'] as Map<String, dynamic>;
        final type = geom['type'] as String;
        final coords = geom['coordinates'] as List<dynamic>;
        if (type == 'Polygon') {
          polys.add(_parseRing(coords[0] as List<dynamic>));
        } else if (type == 'MultiPolygon') {
          for (final poly in coords) {
            polys.add(_parseRing((poly as List<dynamic>)[0] as List<dynamic>));
          }
        }
      }
      if (mounted) setState(() => setter(polys));
    } catch (_) {}
  }

  List<LatLng> _parseRing(List<dynamic> ring) =>
      ring.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

  // ── Raster / Tile layers ──────────────────────────────────────────────────

  ImageProvider _imageProviderFor(RasterLayer r) {
    if (r.assetPath != null) return AssetImage(r.assetPath!);
    if (!kIsWeb && r.filePath != null) return FileImage(File(r.filePath!));
    if (r.fileBytes != null) return MemoryImage(r.fileBytes!);
    return MemoryImage(Uint8List(0));
  }

  List<Widget> _buildAssetRasterLayers() {
    return ref
        .watch(rasterProvider)
        .where((r) => r.visible)
        .map((r) {
          final layer = OverlayImageLayer(
            overlayImages: [
              OverlayImage(
                bounds: LatLngBounds(
                  LatLng(r.southLat, r.westLon),
                  LatLng(r.northLat, r.eastLon),
                ),
                imageProvider: _imageProviderFor(r),
              ),
            ],
          );
          return r.opacity < 0.999
              ? Opacity(opacity: r.opacity, child: layer)
              : layer;
        })
        .toList();
  }

  List<Widget> _buildTileServiceLayers() {
    return ref
        .watch(tileServiceProvider)
        .where((s) => s.visible)
        .map((s) {
          final Widget layer;
          if (s.serviceType == ServiceType.wms) {
            final baseUrl = s.urlTemplate.contains('?')
                ? s.urlTemplate
                : '${s.urlTemplate}?';
            final layerList = s.wmsLayers
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            layer = TileLayer(
              wmsOptions: WMSTileLayerOptions(
                baseUrl: baseUrl,
                layers: layerList,
                format: 'image/png',
                transparent: true,
                version: '1.1.1',
              ),
              userAgentPackageName: 'ge.cartographers.btk',
            );
          } else {
            layer = TileLayer(
              urlTemplate: s.urlTemplate,
              subdomains: s.subdomains,
              userAgentPackageName: 'ge.cartographers.btk',
              tileProvider: kIsWeb ? null : CachedTileProvider(store: _cacheStore),
            );
          }
          return s.opacity < 0.999
              ? Opacity(opacity: s.opacity, child: layer)
              : layer;
        })
        .toList();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    _mapController.move(LatLng(pos.latitude, pos.longitude), 13.0);
    AnalyticsService.logGpsDetect();
  }

  // ── Map tap ──────────────────────────────────────────────────────────────

  void _onMapTap(TapPosition _, LatLng latlng) {
    if (_measureMode != MeasureMode.none) {
      setState(() {
        if (_measureMode == MeasureMode.coordinate) {
          _measurePoints = [latlng];
        } else {
          _measurePoints = [..._measurePoints, latlng];
        }
      });
      return;
    }
    if (!_addingPoint) return;
    setState(() => _addingPoint = false);
    ref
        .read(btkProvider.notifier)
        .add(lat: latlng.latitude, lon: latlng.longitude)
        .then((record) {
      AnalyticsService.logRecordCreated();
      if (!mounted) return;
      context.push('/form', extra: record);
    });
  }

  // ── Measurement ───────────────────────────────────────────────────────────

  Future<void> _buildSearchIndex() async {
    final index = <GeoSearchResult>[];

    Future<void> load(String asset, String field, String label) async {
      try {
        final raw = await rootBundle.loadString(asset);
        final features = (jsonDecode(raw) as Map)['features'] as List;
        for (final f in features) {
          final name = ((f['properties'] as Map)[field] as String?) ?? '';
          if (name.isEmpty) continue;
          final geom = f['geometry'] as Map;
          final coords = geom['coordinates'] as List;
          final rings = geom['type'] == 'Polygon'
              ? [_parseRing(coords[0] as List)]
              : coords
                  .map((p) => _parseRing((p as List)[0] as List))
                  .toList();
          final pts = rings.expand((r) => r).toList();
          if (pts.isEmpty) continue;
          double minLat = pts[0].latitude, maxLat = pts[0].latitude;
          double minLon = pts[0].longitude, maxLon = pts[0].longitude;
          for (final p in pts) {
            if (p.latitude < minLat) minLat = p.latitude;
            if (p.latitude > maxLat) maxLat = p.latitude;
            if (p.longitude < minLon) minLon = p.longitude;
            if (p.longitude > maxLon) maxLon = p.longitude;
          }
          index.add(GeoSearchResult(
            name: name,
            subtitle: label,
            center: LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2),
            bounds: LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon)),
          ));
        }
      } catch (_) {}
    }

    await Future.wait([
      load(AppConstants.regionsGeojsonPath, 'REGION_ENG', 'რეგიონი'),
      load(AppConstants.municipalitiesGeojsonPath, 'DISTR_ENG', 'მუნიციპალიტეტი'),
    ]);
    index.sort((a, b) => a.name.compareTo(b.name));
    if (mounted) setState(() => _searchIndex = index);
  }

  void _openSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MapSearchSheet(
        localIndex: _searchIndex,
        onSelect: (result) {
          if (result.bounds != null) {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: result.bounds!,
                padding: const EdgeInsets.all(48),
              ),
            );
          } else {
            _mapController.move(result.center, 13);
          }
        },
      ),
    );
  }

  void _fitToGeorgia() {
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(41.0, 40.0), LatLng(43.7, 46.8)),
        padding: const EdgeInsets.all(24),
      ),
    );
  }

  void _toggleMeasure() {
    setState(() {
      if (_measureMode == MeasureMode.none) {
        _measureMode = MeasureMode.coordinate;
        _measurePoints = [];
        _addingPoint = false;
        AnalyticsService.logMeasurement('coordinate');
      } else {
        _measureMode = MeasureMode.none;
        _measurePoints = [];
      }
    });
  }

  // ── Weather ───────────────────────────────────────────────────────────────

  void _openWeather() {
    AnalyticsService.logWeatherViewed();
    final center = _mapController.camera.center;
    showWeatherDialog(context, center.latitude, center.longitude);
  }

  // ── GPS Track finished sheet ──────────────────────────────────────────────

  void _showTrackFinishedSheet(BuildContext ctx, GpsTrack track) {
    double totalMeters = 0;
    if (track.points.length >= 2) {
      const calc = Distance();
      for (int i = 1; i < track.points.length; i++) {
        totalMeters += calc(
          LatLng(track.points[i - 1].lat, track.points[i - 1].lon),
          LatLng(track.points[i].lat, track.points[i].lon),
        );
      }
    }

    final duration = track.endedAt != null
        ? track.endedAt!.difference(track.startedAt)
        : Duration.zero;
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    final durationStr = h > 0
        ? '$h სთ $m წთ $s წმ'
        : m > 0
            ? '$m წთ $s წმ'
            : '$s წმ';
    final distStr = totalMeters >= 1000
        ? '${(totalMeters / 1000).toStringAsFixed(2)} კმ'
        : '${totalMeters.toStringAsFixed(0)} მ';

    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.route, size: 28),
              const SizedBox(width: 12),
              Text('GPS ტრეკი დასრულდა',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TrackStat(
                    label: 'მანძილი',
                    value: distStr,
                    icon: Icons.straighten),
                _TrackStat(
                    label: 'ხანგრძლ.',
                    value: durationStr,
                    icon: Icons.timer_outlined),
                _TrackStat(
                    label: 'წერტილი',
                    value: '${track.points.length}',
                    icon: Icons.location_on_outlined),
              ],
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('დახურვა'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('GPX-ის გადმოტვირთვა'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ExportService.shareGpx(track);
                    AnalyticsService.logGpxExported();
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final layers = ref.watch(mapLayersProvider);
    final records = ref.watch(btkProvider);
    final measuring = _measureMode != MeasureMode.none;

    if (!kIsWeb) {
      final awake = ref.watch(settingsProvider.select((s) => s.screenAwake));
      WakelockPlus.toggle(enable: awake);
    }

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: AppConstants.georgiaCenter,
              initialZoom: AppConstants.defaultZoom,
              minZoom: AppConstants.minZoom,
              maxZoom: AppConstants.maxZoom,
              onTap: _onMapTap,
            ),
            children: [
              if (layers.showOsm)
                TileLayer(
                  urlTemplate: AppConstants.osmTileUrl,
                  userAgentPackageName: 'ge.cartographers.btk',
                  tileProvider: kIsWeb
                      ? null
                      : CachedTileProvider(store: _cacheStore),
                ),
              if (layers.showTopo)
                Opacity(
                  opacity: 0.85,
                  child: TileLayer(
                    urlTemplate: AppConstants.topoTileUrl,
                    subdomains: AppConstants.topoSubdomains,
                    userAgentPackageName: 'ge.cartographers.btk',
                    tileProvider: kIsWeb
                        ? null
                        : CachedTileProvider(store: _cacheStore),
                  ),
                ),
              ..._buildTileServiceLayers(),
              if (layers.showMunicipalities && _municipalityPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: _municipalityPolygons
                      .map((pts) => Polygon(
                            points: pts,
                            borderColor: Colors.green.shade700,
                            borderStrokeWidth: 0.8,
                            color: Colors.green.withValues(alpha: 0.04),
                          ))
                      .toList(),
                ),
              if (layers.showRegions && _regionPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: _regionPolygons
                      .map((pts) => Polygon(
                            points: pts,
                            borderColor: Colors.orange.shade700,
                            borderStrokeWidth: 1.5,
                            color: Colors.orange.withValues(alpha: 0.05),
                          ))
                      .toList(),
                ),
              if (layers.showBoundary && _boundaryPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: _boundaryPolygons
                      .map((pts) => Polygon(
                            points: pts,
                            borderColor: Colors.blue.shade700,
                            borderStrokeWidth: 2.0,
                            color: Colors.blue.withValues(alpha: 0.04),
                          ))
                      .toList(),
                ),
              ..._buildAssetRasterLayers(),
              Builder(builder: (ctx) {
                final track = ref.watch(gpsTrackProvider);
                if (track == null || track.points.length < 2) {
                  return const SizedBox.shrink();
                }
                final pts =
                    track.points.map((p) => LatLng(p.lat, p.lon)).toList();
                return PolylineLayer(polylines: [
                  Polyline(
                    points: pts,
                    color: Colors.redAccent,
                    strokeWidth: 3.0,
                  ),
                ]);
              }),
              if (layers.showPoints)
                MarkerLayer(
                  markers: records.map((r) {
                    if (r.latitude == null) return null;
                    return Marker(
                      point: LatLng(r.latitude!, r.longitude!),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => context.push('/form', extra: r),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(blurRadius: 4, color: Colors.black26)
                            ],
                          ),
                          child: const Icon(Icons.location_pin,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    );
                  }).whereType<Marker>().toList(),
                ),
              ...buildMeasurementLayers(
                mode: _measureMode,
                points: _measurePoints,
                scheme: Theme.of(context).colorScheme,
              ),
            ],
          ),

          // ── Adding point hint ───────────────────────────────────────────
          if (_addingPoint)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'რუკაზე დააჭირეთ წერტილის დასამატებლად',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer),
                    ),
                  ),
                ),
              ),
            ),

          // ── Compass badge (Android only, shows when heading known) ─────
          if (!kIsWeb && _compassHeading != null)
            Positioned(
              right: 14,
              top: MediaQuery.of(context).padding.top + 34,
              child: _CompassBadge(heading: _compassHeading!),
            ),

          // ── Right-side buttons ──────────────────────────────────────────
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.search,
                  tooltip: 'ძებნა',
                  onTap: _openSearch,
                ),
                const SizedBox(height: 16),
                _MapButton(
                  icon: Icons.add,
                  onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.remove,
                  onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1),
                ),
                const SizedBox(height: 16),
                _MapButton(
                  icon: Icons.my_location,
                  onTap: _goToMyLocation,
                ),
                const SizedBox(height: 8),
                if (!kIsWeb)
                  Builder(builder: (ctx) {
                    final trackNotifier =
                        ref.read(gpsTrackProvider.notifier);
                    final track = ref.watch(gpsTrackProvider);
                    final isTracking =
                        track != null && track.endedAt == null;
                    return _MapButton(
                      icon: isTracking
                          ? Icons.stop_circle_outlined
                          : Icons.route,
                      active: isTracking,
                      activeColor: Colors.red,
                      onTap: () async {
                        if (isTracking) {
                          final finished =
                              await trackNotifier.stopTracking();
                          if (!ctx.mounted) return;
                          if (finished != null &&
                              finished.points.isNotEmpty) {
                            _showTrackFinishedSheet(ctx, finished);
                          }
                        } else {
                          await trackNotifier.startTracking();
                        }
                      },
                    );
                  }),
                if (!kIsWeb) const SizedBox(height: 8),
                if (!kIsWeb)
                  _MapButton(
                    icon: Icons.history,
                    tooltip: AppLocalizations.of(context)!.trackHistory,
                    onTap: () => context.push('/gps'),
                  ),
                if (!kIsWeb) const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.wb_cloudy_outlined,
                  onTap: _openWeather,
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.travel_explore,
                  onTap: () => context.push('/layers'),
                ),
                const SizedBox(height: 4),
                _MapButton(
                  icon: Icons.layers_outlined,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => const LayerControlPanel(),
                  ),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.zoom_out_map,
                  tooltip: 'საქართველო',
                  onTap: _fitToGeorgia,
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.straighten,
                  active: measuring,
                  onTap: _toggleMeasure,
                ),
              ],
            ),
          ),

          // ── Measurement panel ───────────────────────────────────────────
          // bottom: 0 + SafeArea + padding clears the system nav bar and the
          // bottom bar (12 margin + ~68px buttons + 12 margin = 92) + 8px gap.
          if (measuring)
            Positioned(
              bottom: 0,
              left: 12,
              right: 12,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: MeasurementPanel(
                mode: _measureMode,
                points: _measurePoints,
                onModeChanged: (m) =>
                    setState(() {
                      _measureMode = m;
                      _measurePoints = [];
                    }),
                onUndo: () => setState(() {
                  if (_measurePoints.isNotEmpty) _measurePoints.removeLast();
                }),
                onClear: () => setState(() => _measurePoints = []),
                onClose: _toggleMeasure,
              ),
                ),
              ),
            ),

          // ── Bottom navigation ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(blurRadius: 8, color: Colors.black12)
                  ],
                ),
                child: Builder(builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BottomBarButton(
                        icon: Icons.map_outlined,
                        label: l10n.map,
                        selected: true,
                        onTap: () {},
                      ),
                      _BottomBarButton(
                        icon: Icons.list_alt_outlined,
                        label: l10n.records,
                        onTap: () => context.push('/records'),
                      ),
                      GestureDetector(
                      onTap: () =>
                          setState(() => _addingPoint = !_addingPoint),
                      child: Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: _addingPoint
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(blurRadius: 6, color: Colors.black26)
                          ],
                        ),
                        child: Icon(
                          _addingPoint
                              ? Icons.close
                              : Icons.add_location_alt,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                      _BottomBarButton(
                        icon: Icons.picture_as_pdf_outlined,
                        label: l10n.methodologyShort,
                        onTap: () {
                          AnalyticsService.logPdfOpened();
                          context.push('/pdf');
                        },
                      ),
                      _BottomBarButton(
                        icon: Icons.settings_outlined,
                        label: l10n.paramsShort,
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;
  final String? tooltip;

  const _MapButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.activeColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        active ? (activeColor ?? Theme.of(context).colorScheme.primary) : null;
    Widget child = Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      color: active
          ? (activeColor != null
              ? activeColor!.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.primaryContainer)
          : Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: effectiveColor),
        ),
      ),
    );
    if (tooltip != null) {
      child = Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

class _BottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _BottomBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── GPS track stats tile ──────────────────────────────────────────────────────

class _TrackStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TrackStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6))),
      ],
    );
  }
}

// ── Compass badge ─────────────────────────────────────────────────────────────

class _CompassBadge extends StatelessWidget {
  final double heading;

  const _CompassBadge({required this.heading});

  @override
  Widget build(BuildContext context) {
    final labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final cardinal = labels[((heading + 22.5) % 360 ~/ 45).clamp(0, 7)];

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: heading * 3.14159265 / 180,
              child: Icon(Icons.navigation,
                  size: 16, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 4),
            Text('${heading.round()}°  $cardinal',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
