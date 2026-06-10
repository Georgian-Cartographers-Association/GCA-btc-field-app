import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeoSearchResult {
  final String name;
  final String subtitle;
  final LatLng center;
  final LatLngBounds? bounds;

  const GeoSearchResult({
    required this.name,
    required this.subtitle,
    required this.center,
    this.bounds,
  });
}

class MapSearchSheet extends StatefulWidget {
  final List<GeoSearchResult> localIndex;
  final void Function(GeoSearchResult) onSelect;

  const MapSearchSheet({
    super.key,
    required this.localIndex,
    required this.onSelect,
  });

  @override
  State<MapSearchSheet> createState() => _MapSearchSheetState();
}

class _MapSearchSheetState extends State<MapSearchSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  List<GeoSearchResult> _local = [];
  List<GeoSearchResult> _geo = [];
  bool _loadingGeo = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _ctrl.text.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;

    _filterLocal(q);

    _debounce?.cancel();
    if (q.length >= 2) {
      setState(() => _loadingGeo = true);
      _debounce = Timer(const Duration(milliseconds: 450), () => _fetchNominatim(q));
    } else {
      setState(() {
        _geo = [];
        _loadingGeo = false;
      });
    }
  }

  void _filterLocal(String q) {
    if (q.isEmpty) {
      setState(() => _local = []);
      return;
    }
    final lower = q.toLowerCase();
    setState(() {
      _local = widget.localIndex
          .where((r) => r.name.toLowerCase().contains(lower))
          .take(8)
          .toList();
    });
  }

  Future<void> _fetchNominatim(String q) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'json',
        'countrycodes': 'ge',
        'limit': '8',
        'addressdetails': '1',
        'accept-language': 'ka,en',
      });
      final resp = await http.get(
        uri,
        headers: {'User-Agent': 'btk-field-app/1.0 (Georgian Cartographers Association)'},
      );
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        final results = list.map(_parseNominatimItem).toList();
        setState(() {
          _geo = results;
          _loadingGeo = false;
        });
      } else {
        setState(() {
          _geo = [];
          _loadingGeo = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _geo = [];
          _loadingGeo = false;
        });
      }
    }
  }

  GeoSearchResult _parseNominatimItem(dynamic item) {
    final lat = double.parse(item['lat'] as String);
    final lon = double.parse(item['lon'] as String);

    final bb = item['boundingbox'] as List?;
    LatLngBounds? bounds;
    if (bb != null && bb.length == 4) {
      bounds = LatLngBounds(
        LatLng(double.parse(bb[0] as String), double.parse(bb[2] as String)),
        LatLng(double.parse(bb[1] as String), double.parse(bb[3] as String)),
      );
    }

    final addr = (item['address'] as Map?)?.cast<String, dynamic>() ?? {};
    final name = (addr['city'] ??
            addr['town'] ??
            addr['village'] ??
            addr['hamlet'] ??
            addr['county'] ??
            addr['state'] ??
            item['display_name'])
        .toString();

    final subtitle = _localizeType(item['type'] as String? ?? '');
    return GeoSearchResult(name: name, subtitle: subtitle, center: LatLng(lat, lon), bounds: bounds);
  }

  String _localizeType(String type) => switch (type) {
        'city' || 'town' => 'ქალაქი',
        'village' || 'hamlet' || 'isolated_dwelling' => 'სოფელი',
        'administrative' || 'county' => 'ადმინისტრაციული ერთეული',
        'state' => 'რეგიონი',
        'suburb' || 'neighbourhood' => 'უბანი',
        'river' || 'stream' => 'მდინარე',
        'mountain' || 'peak' => 'მთა',
        _ => 'ადგილი',
      };

  bool get _hasResults => _local.isNotEmpty || _geo.isNotEmpty;

  void _select(GeoSearchResult r) {
    Navigator.pop(context);
    widget.onSelect(r);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ძებნა: სოფელი, ქალაქი, რეგიონი...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() {
                            _local = [];
                            _geo = [];
                            _loadingGeo = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ),

          // Results
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.48,
            ),
            child: _buildResultList(),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    if (_lastQuery.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'ჩაწერეთ ძებნის სიტყვა',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (!_hasResults && !_loadingGeo) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'არაფერი მოიძებნა',
          style: TextStyle(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        if (_local.isNotEmpty) ...[
          _SectionLabel('შრეებში'),
          ..._local.map((r) => _Tile(
                result: r,
                icon: Icons.layers_outlined,
                onTap: () => _select(r),
              )),
        ],
        if (_loadingGeo)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (_geo.isNotEmpty) ...[
          _SectionLabel('ადგილები (OSM)'),
          ..._geo.map((r) => _Tile(
                result: r,
                icon: Icons.place_outlined,
                onTap: () => _select(r),
              )),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final GeoSearchResult result;
  final IconData icon;
  final VoidCallback onTap;
  const _Tile({required this.result, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      title: Text(result.name, style: const TextStyle(fontSize: 14)),
      subtitle: Text(result.subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      dense: true,
      onTap: onTap,
    );
  }
}
