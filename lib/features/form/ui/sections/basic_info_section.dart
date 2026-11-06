import 'package:flutter/material.dart';
import '../../../../models/btk_record.dart';
import '../widgets/english_field.dart';
import '../../../../utils/coord_converter.dart';
import '../../../gps/ui/track_status_bar.dart' show accuracyColor;
import '../widgets/coord_converter_widget.dart';
import '../../../../l10n/generated/app_localizations.dart';

class BasicInfoSection extends StatefulWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;
  final VoidCallback onDetectGps;
  final VoidCallback? onLinkTrack;
  final List<String> groupSuggestions;

  const BasicInfoSection({
    super.key,
    required this.record,
    required this.onChanged,
    required this.onDetectGps,
    this.onLinkTrack,
    this.groupSuggestions = const [],
  });

  @override
  State<BasicInfoSection> createState() => _BasicInfoSectionState();
}

class _BasicInfoSectionState extends State<BasicInfoSection> {
  late final TextEditingController _dateCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;
  late final TextEditingController _altCtrl;
  late final TextEditingController _aspectCtrl;

  String? _latError;
  String? _lonError;
  String? _altError;
  String? _aspectError;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _dateCtrl = TextEditingController(text: r.date.toString().split(' ')[0]);
    _locationCtrl = TextEditingController(text: r.location);
    _latCtrl = TextEditingController(text: r.latitude?.toStringAsFixed(6) ?? '');
    _lonCtrl = TextEditingController(text: r.longitude?.toStringAsFixed(6) ?? '');
    _altCtrl = TextEditingController(text: r.altitude != null ? r.altitude!.toStringAsFixed(0) : '');
    _aspectCtrl = TextEditingController(text: r.aspect != null ? r.aspect!.toStringAsFixed(0) : '');
  }

  @override
  void didUpdateWidget(covariant BasicInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final r = widget.record;

    // Date is readOnly — simple string compare is safe
    final newDate = r.date.toString().split(' ')[0];
    if (_dateCtrl.text != newDate) _dateCtrl.text = newDate;

    // Numeric fields: compare PARSED values, not formatted strings.
    // This avoids fighting with in-progress typing: typing '41.12' and having
    // the record round-trip to '41.120000' would reset the cursor mid-keystroke.
    // We only update when the record's value is genuinely different (e.g. GPS fix).
    _syncNumericCtrl(_latCtrl, r.latitude, 6);
    _syncNumericCtrl(_lonCtrl, r.longitude, 6);
    _syncNumericCtrl(_altCtrl, r.altitude, 0);
    _syncNumericCtrl(_aspectCtrl, r.aspect, 0);
  }

  /// Updates [ctrl] only if the record [value] can't be represented by what
  /// the controller already contains (i.e. it's an external change, not a
  /// formatting artefact of the user's own keystrokes).
  void _syncNumericCtrl(
      TextEditingController ctrl, double? value, int decimals) {
    if (double.tryParse(ctrl.text) != value) {
      ctrl.text = value != null ? value.toStringAsFixed(decimals) : '';
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _locationCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _altCtrl.dispose();
    _aspectCtrl.dispose();
    super.dispose();
  }

  String? _validateLat(String v) {
    final l10n = AppLocalizations.of(context)!;
    if (v.trim().isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return l10n.numbersOnly;
    if (n < -90 || n > 90) return '-90 … 90';
    return null;
  }

  String? _validateLon(String v) {
    final l10n = AppLocalizations.of(context)!;
    if (v.trim().isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return l10n.numbersOnly;
    if (n < -180 || n > 180) return '-180 … 180';
    return null;
  }

  String? _validateAlt(String v) {
    final l10n = AppLocalizations.of(context)!;
    if (v.trim().isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return l10n.numbersOnly;
    if (n < -500 || n > 9000) return l10n.altitudeRange;
    return null;
  }

  String? _validateAspect(String v) {
    final l10n = AppLocalizations.of(context)!;
    if (v.trim().isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return l10n.numbersOnly;
    if (n < 0 || n > 360) return '0 … 360°';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = widget.record;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, l10n.btkFullTitle),
          const SizedBox(height: 4),
          Text('ID: ${r.id}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),

          // Fill language
          Text(l10n.fillLanguage, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: fillKa, label: Text(l10n.fillLanguageKa)),
              ButtonSegment(value: fillEn, label: Text(l10n.fillLanguageEn)),
              ButtonSegment(value: fillBoth, label: Text(l10n.fillLanguageBoth)),
            ],
            selected: {r.fillLang},
            showSelectedIcon: false,
            onSelectionChanged: (s) => widget.onChanged(r..fillLanguage = s.first),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.fillLanguageHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          // Date
          TextField(
            controller: _dateCtrl,
            readOnly: true,
            decoration: InputDecoration(
              labelText: l10n.date,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today, size: 18),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: r.date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) widget.onChanged(r..date = d);
                },
              ),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Group
          Autocomplete<String>(
            initialValue: TextEditingValue(text: r.group),
            optionsBuilder: (value) {
              final q = value.text.trim().toLowerCase();
              return widget.groupSuggestions
                  .where((g) => g.toLowerCase().contains(q));
            },
            onSelected: (g) => widget.onChanged(r..group = g),
            fieldViewBuilder: (context, ctrl, focus, _) => TextField(
              controller: ctrl,
              focusNode: focus,
              onChanged: (v) => widget.onChanged(r..group = v),
              decoration: InputDecoration(
                labelText: l10n.recordGroup,
                hintText: l10n.recordGroupHint,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Location
          TextField(
            controller: _locationCtrl,
            onChanged: (v) => widget.onChanged(r..location = v),
            decoration: InputDecoration(
              labelText: l10n.location,
              hintText: l10n.locationHint,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          if (r.isBilingual)
            EnglishField(
              values: r.english,
              fieldKey: 'location',
              label: l10n.location,
              onChanged: () => widget.onChanged(r),
            ),
          const SizedBox(height: 16),

          Text(l10n.coordinates, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),

          // Lat / Lon row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (v) {
                    final err = _validateLat(v);
                    setState(() => _latError = err);
                    if (err == null) {
                      widget.onChanged(r
                        ..latitude = CoordConverter.parseCoord(v)
                        ..coordAccuracy = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.latitude,
                    errorText: _latError,
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lonCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (v) {
                    final err = _validateLon(v);
                    setState(() => _lonError = err);
                    if (err == null) {
                      widget.onChanged(r
                        ..longitude = CoordConverter.parseCoord(v)
                        ..coordAccuracy = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.longitude,
                    errorText: _lonError,
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Altitude / Aspect row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _altCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (v) {
                    final err = _validateAlt(v);
                    setState(() => _altError = err);
                    if (err == null) {
                      widget.onChanged(r..altitude = double.tryParse(v));
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.altitudeM,
                    errorText: _altError,
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _aspectCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final err = _validateAspect(v);
                    setState(() => _aspectError = err);
                    if (err == null) {
                      widget.onChanged(r..aspect = double.tryParse(v));
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.aspectDeg,
                    hintText: '0–360',
                    errorText: _aspectError,
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: widget.onDetectGps,
            icon: const Icon(Icons.gps_fixed, size: 18),
            label: Text(l10n.useGps),
          ),
          if (r.coordAccuracy != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.accuracyValue(r.coordAccuracy!.round()),
                style: TextStyle(
                    fontSize: 12, color: accuracyColor(r.coordAccuracy!)),
              ),
            ),
          if (widget.onLinkTrack != null)
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                    onPressed: widget.onLinkTrack,
                    icon: const Icon(Icons.route, size: 18),
                    label: Text(r.trackId.isEmpty
                        ? l10n.linkTrack
                        : l10n.linkedTrack(r.trackId)),
                  ),
                ),
                if (r.trackId.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.link_off, size: 18),
                    tooltip: l10n.unlinkTrack,
                    onPressed: () => widget.onChanged(r..trackId = ''),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          CoordConverterWidget(
            latitude: r.latitude,
            longitude: r.longitude,
            onApply: (lat, lon) {
              _latCtrl.text = lat.toStringAsFixed(6);
              _lonCtrl.text = lon.toStringAsFixed(6);
              widget.onChanged(r
                ..latitude = lat
                ..longitude = lon
                ..coordAccuracy = null);
            },
          ),
        ],
      ),
    );
  }
}

Widget _sectionHeader(BuildContext context, String title) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        )),
  );
}
