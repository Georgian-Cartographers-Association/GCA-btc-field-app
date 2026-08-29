import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/coord_converter.dart';

/// Collapsible coordinate converter with two directions:
///   1. DD / DM / DMS → all formats (DD, DM, DMS, UTM37N, UTM38N)
///   2. UTM 37N / 38N → DD  (inverse projection)
class CoordConverterWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final void Function(double lat, double lon) onApply;

  const CoordConverterWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onApply,
  });

  @override
  State<CoordConverterWidget> createState() => _CoordConverterWidgetState();
}

enum _Mode { toUtm, fromUtm }

class _CoordConverterWidgetState extends State<CoordConverterWidget> {
  bool _expanded = false;
  _Mode _mode = _Mode.toUtm;

  // ── mode 1: DD/DM/DMS → UTM ──────────────────────────────────────────────
  late final TextEditingController _inputLatCtrl;
  late final TextEditingController _inputLonCtrl;
  double? _parsedLat;
  double? _parsedLon;
  String? _latErr;
  String? _lonErr;

  // ── mode 2: UTM → DD ─────────────────────────────────────────────────────
  final TextEditingController _eastingCtrl = TextEditingController();
  final TextEditingController _northingCtrl = TextEditingController();
  int _utmZone = 38; // 37 or 38
  String? _utmErr;
  double? _utmResultLat;
  double? _utmResultLon;

  @override
  void initState() {
    super.initState();
    _parsedLat = widget.latitude;
    _parsedLon = widget.longitude;
    _inputLatCtrl = TextEditingController(
        text: widget.latitude?.toStringAsFixed(6) ?? '');
    _inputLonCtrl = TextEditingController(
        text: widget.longitude?.toStringAsFixed(6) ?? '');
  }

  @override
  void didUpdateWidget(covariant CoordConverterWidget old) {
    super.didUpdateWidget(old);
    if (widget.latitude != old.latitude && widget.latitude != null) {
      final cur = double.tryParse(_inputLatCtrl.text);
      if (cur == null || cur == old.latitude) {
        _inputLatCtrl.text = widget.latitude!.toStringAsFixed(6);
        _parsedLat = widget.latitude;
      }
    }
    if (widget.longitude != old.longitude && widget.longitude != null) {
      final cur = double.tryParse(_inputLonCtrl.text);
      if (cur == null || cur == old.longitude) {
        _inputLonCtrl.text = widget.longitude!.toStringAsFixed(6);
        _parsedLon = widget.longitude;
      }
    }
  }

  @override
  void dispose() {
    _inputLatCtrl.dispose();
    _inputLonCtrl.dispose();
    _eastingCtrl.dispose();
    _northingCtrl.dispose();
    super.dispose();
  }

  void _parseForwardInputs() {
    final lat = CoordConverter.parseCoord(_inputLatCtrl.text);
    final lon = CoordConverter.parseCoord(_inputLonCtrl.text);
    setState(() {
      _parsedLat = lat;
      _parsedLon = lon;
      _latErr = lat == null && _inputLatCtrl.text.isNotEmpty
          ? 'DD, DM ან DMS ფორმატი'
          : null;
      _lonErr = lon == null && _inputLonCtrl.text.isNotEmpty
          ? 'DD, DM ან DMS ფორმატი'
          : null;
    });
  }

  void _convertFromUtm() {
    final e = double.tryParse(_eastingCtrl.text.replaceAll(' ', ''));
    final n = double.tryParse(_northingCtrl.text.replaceAll(' ', ''));
    if (e == null || n == null) {
      setState(() {
        _utmErr = 'E და N რიცხვებია';
        _utmResultLat = null;
        _utmResultLon = null;
      });
      return;
    }
    try {
      final (lat, lon) = _utmZone == 37
          ? CoordConverter.fromUtm37N(e, n)
          : CoordConverter.fromUtm38N(e, n);
      final inBounds = CoordConverter.inGeorgiaBounds(lat, lon);
      setState(() {
        _utmResultLat = lat;
        _utmResultLon = lon;
        _utmErr = inBounds ? null : 'საქართველოს საზღვრების გარეთ';
      });
    } catch (_) {
      setState(() {
        _utmErr = 'კონვერტაციის შეცდომა';
        _utmResultLat = null;
        _utmResultLon = null;
      });
    }
  }

  void _applyCoords(double lat, double lon) {
    widget.onApply(lat, lon);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('კოორდინატები ფორმაში ჩაიწერა'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'კოორდინატების კონვერტერი',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: scheme.primary),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode toggle
                  SegmentedButton<_Mode>(
                    segments: const [
                      ButtonSegment(
                        value: _Mode.toUtm,
                        icon: Icon(Icons.arrow_forward, size: 14),
                        label: Text('DD→UTM'),
                      ),
                      ButtonSegment(
                        value: _Mode.fromUtm,
                        icon: Icon(Icons.arrow_back, size: 14),
                        label: Text('UTM→DD'),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) =>
                        setState(() => _mode = s.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_mode == _Mode.toUtm)
                    _buildForwardMode(context, scheme)
                  else
                    _buildInverseMode(context, scheme),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Mode 1: DD / DM / DMS → all formats ───────────────────────────────

  Widget _buildForwardMode(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _inputLatCtrl,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _parseForwardInputs(),
                decoration: InputDecoration(
                  labelText: 'განედი',
                  hintText: 'DD / DM / DMS',
                  errorText: _latErr,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _inputLonCtrl,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _parseForwardInputs(),
                onSubmitted: (_) => _parseForwardInputs(),
                decoration: InputDecoration(
                  labelText: 'გრძედი',
                  hintText: 'DD / DM / DMS',
                  errorText: _lonErr,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_parsedLat != null && _parsedLon != null) ...[
          _buildForwardResults(context, _parsedLat!, _parsedLon!),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _applyCoords(_parsedLat!, _parsedLon!),
            child: const Text('ჩაწერა ფორმაში'),
          ),
        ] else
          Text(
            'შეიყვანეთ კოორდინატები ნებისმიერ ფორმატში',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildForwardResults(
      BuildContext context, double lat, double lon) {
    final inBounds = CoordConverter.inGeorgiaBounds(lat, lon);
    final utm37 = CoordConverter.toUtm37N(lat, lon);
    final utm38 = CoordConverter.toUtm38N(lat, lon);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!inBounds) _boundsWarning(context),
        _ResultRow(
          label: 'DD',
          value: '${lat.toStringAsFixed(6)},  ${lon.toStringAsFixed(6)}',
          copy: '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
        ),
        _ResultRow(
          label: 'DM',
          value:
              '${CoordConverter.ddToDm(lat, isLat: true)}  ${CoordConverter.ddToDm(lon, isLat: false)}',
          copy:
              '${CoordConverter.ddToDm(lat, isLat: true)}, ${CoordConverter.ddToDm(lon, isLat: false)}',
        ),
        _ResultRow(
          label: 'DMS',
          value:
              '${CoordConverter.ddToDms(lat, isLat: true)}  ${CoordConverter.ddToDms(lon, isLat: false)}',
          copy:
              '${CoordConverter.ddToDms(lat, isLat: true)}, ${CoordConverter.ddToDms(lon, isLat: false)}',
        ),
        _ResultRow(
            label: 'UTM 37N',
            value: utm37.formatted(),
            copy: utm37.formatted()),
        _ResultRow(
            label: 'UTM 38N',
            value: utm38.formatted(),
            copy: utm38.formatted()),
      ],
    );
  }

  // ── Mode 2: UTM → DD ───────────────────────────────────────────────────

  Widget _buildInverseMode(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Zone selector
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 37, label: Text('UTM 37N')),
            ButtonSegment(value: 38, label: Text('UTM 38N')),
          ],
          selected: {_utmZone},
          onSelectionChanged: (s) {
            setState(() {
              _utmZone = s.first;
              _utmErr = null;
              _utmResultLat = null;
              _utmResultLon = null;
            });
          },
          style: ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        const SizedBox(height: 10),

        // E / N inputs
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _eastingCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {
                  _utmErr = null;
                  _utmResultLat = null;
                  _utmResultLon = null;
                }),
                decoration: const InputDecoration(
                  labelText: 'Easting (E)',
                  hintText: '450000',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _northingCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _convertFromUtm(),
                onChanged: (_) => setState(() {
                  _utmErr = null;
                  _utmResultLat = null;
                  _utmResultLon = null;
                }),
                decoration: const InputDecoration(
                  labelText: 'Northing (N)',
                  hintText: '4610000',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        FilledButton.tonal(
          onPressed: _convertFromUtm,
          child: const Text('კონვერტაცია'),
        ),

        if (_utmErr != null) ...[
          const SizedBox(height: 6),
          _boundsWarning(context, msg: _utmErr),
        ],

        if (_utmResultLat != null && _utmResultLon != null) ...[
          const SizedBox(height: 10),
          _buildInverseResults(context, _utmResultLat!, _utmResultLon!),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _applyCoords(_utmResultLat!, _utmResultLon!),
            child: const Text('ჩაწერა ფორმაში (DD)'),
          ),
        ],
      ],
    );
  }

  Widget _buildInverseResults(
      BuildContext context, double lat, double lon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResultRow(
          label: 'DD',
          value: '${lat.toStringAsFixed(6)},  ${lon.toStringAsFixed(6)}',
          copy: '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
        ),
        _ResultRow(
          label: 'DM',
          value:
              '${CoordConverter.ddToDm(lat, isLat: true)}  ${CoordConverter.ddToDm(lon, isLat: false)}',
          copy:
              '${CoordConverter.ddToDm(lat, isLat: true)}, ${CoordConverter.ddToDm(lon, isLat: false)}',
        ),
        _ResultRow(
          label: 'DMS',
          value:
              '${CoordConverter.ddToDms(lat, isLat: true)}  ${CoordConverter.ddToDms(lon, isLat: false)}',
          copy:
              '${CoordConverter.ddToDms(lat, isLat: true)}, ${CoordConverter.ddToDms(lon, isLat: false)}',
        ),
      ],
    );
  }

  Widget _boundsWarning(BuildContext context, {String? msg}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, size: 16, color: scheme.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              msg ?? 'კოორდინატები საქართველოს საზღვრების გარეთ',
              style: TextStyle(fontSize: 12, color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared result row ────────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final String copy;

  const _ResultRow(
      {required this.label, required this.value, required this.copy});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: copy));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('კოპირებულია'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ));
        },
        child: Row(
          children: [
            SizedBox(
              width: 68,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontFamily: 'monospace')),
            ),
            Icon(Icons.copy, size: 14, color: scheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}
