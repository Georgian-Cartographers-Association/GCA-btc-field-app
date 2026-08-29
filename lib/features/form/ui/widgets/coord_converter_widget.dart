import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/coord_converter.dart';

/// Collapsible in-form coordinate converter.
/// Shows DD, DM, DMS, UTM37N, UTM38N for the current lat/lon.
/// Has a "ჩაწერა ფორმაში" button that writes parsed DD back to the form.
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

class _CoordConverterWidgetState extends State<CoordConverterWidget> {
  bool _expanded = false;

  // Manual input controllers
  late final TextEditingController _inputLatCtrl;
  late final TextEditingController _inputLonCtrl;
  double? _parsedLat;
  double? _parsedLon;
  String? _latErr;
  String? _lonErr;

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
    // Sync from GPS fix only if fields are empty or match old value
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
    super.dispose();
  }

  void _parseInputs() {
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
          // ── Header ─────────────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz,
                      size: 18, color: scheme.primary),
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

          // ── Body ───────────────────────────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Input row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputLatCtrl,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => _parseInputs(),
                          decoration: InputDecoration(
                            labelText: 'განედი',
                            hintText: 'DD / DM / DMS',
                            errorText: _latErr,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
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
                          onChanged: (_) => _parseInputs(),
                          onSubmitted: (_) => _parseInputs(),
                          decoration: InputDecoration(
                            labelText: 'გრძედი',
                            hintText: 'DD / DM / DMS',
                            errorText: _lonErr,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Results
                  if (_parsedLat != null && _parsedLon != null) ...[
                    _buildResults(context, _parsedLat!, _parsedLon!),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () {
                        widget.onApply(_parsedLat!, _parsedLon!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('კოორდინატები ფორმაში ჩაიწერა'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('ჩაწერა ფორმაში'),
                    ),
                  ] else
                    Text(
                      'შეიყვანეთ კოორდინატები ნებისმიერ ფორმატში',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(
      BuildContext context, double lat, double lon) {
    final scheme = Theme.of(context).colorScheme;
    final inBounds = CoordConverter.inGeorgiaBounds(lat, lon);
    final utm37 = CoordConverter.toUtm37N(lat, lon);
    final utm38 = CoordConverter.toUtm38N(lat, lon);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!inBounds)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined,
                    size: 16, color: scheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'კოორდინატები საქართველოს საზღვრების გარეთ',
                    style: TextStyle(
                        fontSize: 12, color: scheme.error),
                  ),
                ),
              ],
            ),
          ),
        _ResultRow(
            label: 'DD',
            value:
                '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
            copy:
                '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}'),
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
}

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
