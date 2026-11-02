import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/app_messenger.dart';
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
import '../domain/map_toolbar.dart';
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
import '../../form/ui/widgets/record_tools.dart' show editedStamp;
import '../../records/domain/record_filter.dart';
import '../../records/ui/record_filter_sheet.dart';
import '../domain/geojson_parse.dart';
import '../../../models/btk_record.dart';
import '../../../models/record_quality.dart';
import '../../gps/domain/location_settings.dart';
import '../../gps/ui/location_access.dart';
import '../../gps/ui/track_status_bar.dart';
import '../../../database/btk_database.dart';
import '../../settings/domain/settings_provider.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/export_service.dart';
import '../../../l10n/localized_text.dart';

// Room the toolbar leaves above itself, and below for the bottom bar (12 margin
// + ~68 buttons + 12 margin) with an 8 gap.
const _toolbarTop = 80.0;
const _bottomBarSpace = 100.0;

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
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkInterruptedTrack());
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
      final polys = await parsePolygons(raw);
      if (mounted) setState(() => setter(polys));
    } catch (_) {}
  }

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
              userAgentPackageName: 'ge.btc.field_app',
            );
          } else {
            layer = TileLayer(
              urlTemplate: s.urlTemplate,
              subdomains: s.subdomains,
              userAgentPackageName: 'ge.btc.field_app',
              tileProvider: kIsWeb ? null : CachedTileProvider(store: _cacheStore),
            );
          }
          return s.opacity < 0.999
              ? Opacity(opacity: s.opacity, child: layer)
              : layer;
        })
        .toList();
  }

  // ── Interrupted track ─────────────────────────────────────────────────────

  LocationSettings _trackSettings(AppLocalizations l10n) => trackLocationSettings(
        notificationTitle: l10n.trackNotificationTitle,
        notificationText: l10n.trackNotificationText,
      );

  // A crash or a restart leaves a track with no end. The newest one is offered
  // for resuming, and older ones are closed with their points kept.
  Future<void> _checkInterruptedTrack() async {
    final notifier = ref.read(gpsTrackProvider.notifier);
    if (notifier.isTracking) return;
    final List<GpsTrack> tracks;
    try {
      tracks = await BtkDatabase.getUnfinishedTracks();
    } catch (_) {
      return;
    }
    if (tracks.isEmpty || !mounted || notifier.isTracking) return;

    Future<void> close(GpsTrack t) => BtkDatabase.finishTrack(
        t.id, t.points.isNotEmpty ? t.points.last.time : t.startedAt);
    try {
      for (final t in tracks.skip(1)) {
        await close(t);
      }
    } catch (_) {
      // They stay as interrupted, and the check runs again on the next start.
    }
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final latest = tracks.first;
    final goOn = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.trackInterruptedTitle),
        content: Text(l10n.trackInterruptedMessage(latest.points.length)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: Text(l10n.finishAction)),
          FilledButton(
              onPressed: () => Navigator.pop(dCtx, true),
              child: Text(l10n.continueAction)),
        ],
      ),
    );
    if (!mounted) return;
    if (goOn == true && await ensureLocationAccess(context)) {
      notifier.resume(latest, _trackSettings(l10n));
      return;
    }
    if (goOn != true) {
      try {
        await close(latest);
      } catch (_) {
        AppMessenger.showError((l10n) => l10n.trackSaveFailed);
      }
    }
  }

  // ── Records and tracks on the map ─────────────────────────────────────────

  void _fitTrack(GpsTrack track) {
    if (track.points.isEmpty) return;
    final pts = [for (final p in track.points) LatLng(p.lat, p.lon)];
    if (pts.length == 1) {
      _mapController.move(pts.first, 15);
      return;
    }
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(pts),
      padding: const EdgeInsets.all(48),
    ));
  }

  void _showRecordsInView() {
    final l10n = AppLocalizations.of(context)!;
    final bounds = _mapController.camera.visibleBounds;
    final filter = ref.read(recordFilterProvider);
    final inView = recordsWithin(
      filter.apply(ref.read(btkProvider)),
      contains: bounds.contains,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(l10n.recordsInView,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(l10n.recordsCount(inView.length)),
              ),
              for (final r in inView)
                ListTile(
                  leading: SizedBox(width: 28, height: 28, child: _RecordSymbol(record: r)),
                  title: Text(r.name.isNotEmpty ? r.name : l10n.btkNumber(r.id)),
                  subtitle: Text(
                      [if (r.location.isNotEmpty) r.location, if (r.group.isNotEmpty) r.group]
                          .join(' · ')),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/form', extra: r);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    if (!await ensureLocationAccess(context)) return;
    final Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
    } catch (_) {
      AppMessenger.showError((l10n) => l10n.locationFailed);
      return;
    }
    if (!mounted) return;
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
    final track = ref.read(gpsTrackProvider);
    ref
        .read(btkProvider.notifier)
        .add(
          lat: latlng.latitude,
          lon: latlng.longitude,
          trackId: track != null && track.endedAt == null ? track.id : '',
        )
        .then((record) {
      AnalyticsService.logRecordCreated();
      if (!mounted) return;
      context.push('/form', extra: record);
    }, onError: (Object _) {
      AppMessenger.showError((l10n) => l10n.saveFailed);
    });
  }

  // ── Measurement ───────────────────────────────────────────────────────────

  Future<void> _buildSearchIndex() async {
    final index = <GeoSearchResult>[];

    Future<void> load(String asset, String field, LocalizedText label) async {
      try {
        final raw = await rootBundle.loadString(asset);
        for (final p in await parsePlaces(raw, field)) {
          index.add(GeoSearchResult(
            name: p.name,
            subtitle: label,
            center: LatLng((p.minLat + p.maxLat) / 2, (p.minLon + p.maxLon) / 2),
            bounds: LatLngBounds(LatLng(p.minLat, p.minLon), LatLng(p.maxLat, p.maxLon)),
          ));
        }
      } catch (_) {}
    }

    await Future.wait([
      load(AppConstants.regionsGeojsonPath, 'REGION_ENG', (l10n) => l10n.placeRegion),
      load(AppConstants.municipalitiesGeojsonPath, 'DISTR_ENG', (l10n) => l10n.placeMunicipality),
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

  // ── Right-side toolbar ────────────────────────────────────────────────────

  Future<void> _toggleTrack() async {
    final notifier = ref.read(gpsTrackProvider.notifier);
    if (notifier.isTracking) {
      final finished = await notifier.stopTracking();
      if (!mounted) return;
      if (finished != null && finished.points.isNotEmpty) {
        _showTrackFinishedSheet(context, finished);
      }
    } else {
      if (!await ensureLocationAccess(context)) return;
      if (!mounted) return;
      try {
        await notifier.startTracking(_trackSettings(AppLocalizations.of(context)!));
      } catch (_) {
        AppMessenger.showError((l10n) => l10n.trackStartFailed);
      }
    }
  }

  void _zoomBy(double change) => _mapController.move(
      _mapController.camera.center, _mapController.camera.zoom + change);

  void _openLayerPanel() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => const LayerControlPanel(),
      );

  /// In display order. A lower rank stays on screen longer when space is short.
  List<_MapTool> _mapTools(
      AppLocalizations l10n, bool filtering, bool measuring) {
    final track = ref.watch(gpsTrackProvider);
    final tracking = track != null && track.endedAt == null;
    return [
      _MapTool(Icons.search, l10n.search, _openSearch, rank: 3),
      _MapTool(Icons.format_list_bulleted, l10n.recordsInView, _showRecordsInView,
          rank: 7),
      _MapTool(filtering ? Icons.filter_alt : Icons.filter_alt_outlined,
          l10n.filterTitle, () => showRecordFilterSheet(context),
          rank: 6, active: filtering),
      _MapTool(Icons.add, l10n.zoomIn, () => _zoomBy(1), rank: 4),
      _MapTool(Icons.remove, l10n.zoomOut, () => _zoomBy(-1), rank: 5),
      _MapTool(Icons.my_location, l10n.myLocation, _goToMyLocation, rank: 0),
      if (!kIsWeb) ...[
        _MapTool(tracking ? Icons.stop_circle_outlined : Icons.route,
            tracking ? l10n.trackStop : l10n.trackStart, _toggleTrack,
            rank: 1, active: tracking, activeColor: Colors.red),
        _MapTool(Icons.history, l10n.trackHistory, () => context.push('/gps'),
            rank: 9),
      ],
      _MapTool(Icons.wb_cloudy_outlined, l10n.weatherForecast, _openWeather,
          rank: 10),
      _MapTool(Icons.travel_explore, l10n.dataLayers, () => context.push('/layers'),
          rank: 11),
      _MapTool(Icons.layers_outlined, l10n.layers, _openLayerPanel, rank: 2),
      _MapTool(Icons.zoom_out_map, l10n.georgia, _fitToGeorgia, rank: 12),
      _MapTool(Icons.straighten, l10n.measureTool, _toggleMeasure,
          rank: 8, active: measuring),
    ];
  }

  Widget _buildToolbar(AppLocalizations l10n, bool filtering, bool measuring) {
    final media = MediaQuery.of(context);
    final split = splitMapTools(
      _mapTools(l10n, filtering, measuring),
      height: media.size.height -
          media.padding.top -
          media.padding.bottom -
          _toolbarTop -
          _bottomBarSpace,
      rank: (t) => t.rank,
    );
    return Column(
      spacing: mapButtonGap,
      children: [
        for (final t in split.shown)
          _MapButton(
            icon: t.icon,
            tooltip: t.label,
            onTap: t.onTap,
            active: t.active,
            activeColor: t.activeColor,
          ),
        if (split.hidden.isNotEmpty)
          _MapButton(
            icon: Icons.more_horiz,
            tooltip: l10n.mapTools,
            active: split.hidden.any((t) => t.active),
            onTap: () => _showToolsMenu(l10n, split.hidden),
          ),
      ],
    );
  }

  void _showToolsMenu(AppLocalizations l10n, List<_MapTool> tools) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final t in tools)
                ListTile(
                  leading: Icon(t.icon),
                  title: Text(t.label),
                  selected: t.active,
                  onTap: () {
                    Navigator.pop(ctx);
                    t.onTap();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── GPS Track finished sheet ──────────────────────────────────────────────

  void _showTrackFinishedSheet(BuildContext ctx, GpsTrack track) {
    final l10n = AppLocalizations.of(context)!;
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
        ? '$h ${l10n.unitHour} $m ${l10n.unitMin} $s ${l10n.unitSec}'
        : m > 0
            ? '$m ${l10n.unitMin} $s ${l10n.unitSec}'
            : '$s ${l10n.unitSec}';
    final distStr = totalMeters >= 1000
        ? '${(totalMeters / 1000).toStringAsFixed(2)} ${l10n.unitKm}'
        : '${totalMeters.toStringAsFixed(0)} ${l10n.unitM}';

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
              Text(l10n.gpsTrackFinished,
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
                    label: l10n.distance,
                    value: distStr,
                    icon: Icons.straighten),
                _TrackStat(
                    label: l10n.durationShort,
                    value: durationStr,
                    icon: Icons.timer_outlined),
                _TrackStat(
                    label: l10n.trackPoints,
                    value: '${track.points.length}',
                    icon: Icons.location_on_outlined),
              ],
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close),
                  label: Text(l10n.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.downloadGpx),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ExportService.shareGpx(track, l10n);
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
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(recordFilterProvider);
    final shownTrack = ref.watch(shownTrackProvider);
    ref.listen(shownTrackProvider, (_, track) {
      if (track != null) _fitTrack(track);
    });
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
                  userAgentPackageName: 'ge.btc.field_app',
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
                    userAgentPackageName: 'ge.btc.field_app',
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
              if (shownTrack != null && shownTrack.points.isNotEmpty) ...[
                PolylineLayer(polylines: [
                  Polyline(
                    points: [
                      for (final p in shownTrack.points) LatLng(p.lat, p.lon)
                    ],
                    color: Colors.indigo,
                    strokeWidth: 3.0,
                  ),
                ]),
                MarkerLayer(markers: [
                  for (final (p, color) in [
                    (shownTrack.points.first, Colors.green),
                    (shownTrack.points.last, Colors.red),
                  ])
                    Marker(
                      point: LatLng(p.lat, p.lon),
                      width: 14,
                      height: 14,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ]),
              ],
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
                  markers: filter.apply(records).map((r) {
                    final point = r.mapPoint;
                    if (point == null) return null;
                    return Marker(
                      point: point,
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => context.push('/form', extra: r),
                        child: _RecordSymbol(record: r),
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

          // ── Filter and shown track, so nothing looks missing ────────────
          Positioned(
            left: 12,
            right: 72,
            top: MediaQuery.of(context).padding.top + 52,
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (filter.isActive)
                  InputChip(
                    avatar: const Icon(Icons.filter_alt, size: 16),
                    label: Text(l10n.filterShown(
                        filter.apply(records).length, records.length)),
                    onPressed: () => showRecordFilterSheet(context),
                    onDeleted: () => ref
                        .read(recordFilterProvider.notifier)
                        .state = const RecordFilter(),
                  ),
                if (shownTrack != null)
                  InputChip(
                    avatar: const Icon(Icons.route, size: 16),
                    label: Text(editedStamp(shownTrack.startedAt)),
                    onPressed: () => _fitTrack(shownTrack),
                    onDeleted: () =>
                        ref.read(shownTrackProvider.notifier).state = null,
                  ),
              ],
            ),
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
                      l10n.tapMapToAddPoint,
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
          if (!kIsWeb)
            Positioned(
              left: 12,
              right: 72,
              top: MediaQuery.of(context).padding.top + 12,
              child: const Align(
                  alignment: Alignment.centerLeft, child: TrackStatusBar()),
            ),
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + _toolbarTop,
            child: _buildToolbar(l10n, filter.isActive, measuring),
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

class _MapTool {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int rank;
  final bool active;
  final Color? activeColor;

  const _MapTool(this.icon, this.label, this.onTap,
      {required this.rank, this.active = false, this.activeColor});
}

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
          width: mapButtonSize,
          height: mapButtonSize,
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

// ── A record on the map ───────────────────────────────────────────────────────

/// Colour shows the group. A hollow symbol means the record is unfinished.
class _RecordSymbol extends StatelessWidget {
  final BtkRecord record;
  const _RecordSymbol({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = record.group.trim().isEmpty
        ? Theme.of(context).colorScheme.primary
        : groupColor(record.group);
    final hollow = record.isUnfinished;
    return Container(
      decoration: BoxDecoration(
        color: hollow ? Colors.white : color,
        shape: BoxShape.circle,
        border: Border.all(color: hollow ? color : Colors.white, width: 2),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Icon(Icons.location_pin, color: hollow ? color : Colors.white, size: 18),
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
