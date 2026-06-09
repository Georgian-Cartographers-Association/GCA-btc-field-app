import 'package:flutter/material.dart';
import '../../../../models/btk_record.dart';

class BasicInfoSection extends StatefulWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;
  final VoidCallback onDetectGps;

  const BasicInfoSection({
    super.key,
    required this.record,
    required this.onChanged,
    required this.onDetectGps,
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

    final newDate = r.date.toString().split(' ')[0];
    if (_dateCtrl.text != newDate) _dateCtrl.text = newDate;

    final newLat = r.latitude?.toStringAsFixed(6) ?? '';
    if (_latCtrl.text != newLat) _latCtrl.text = newLat;

    final newLon = r.longitude?.toStringAsFixed(6) ?? '';
    if (_lonCtrl.text != newLon) _lonCtrl.text = newLon;

    final newAlt = r.altitude != null ? r.altitude!.toStringAsFixed(0) : '';
    if (_altCtrl.text != newAlt) _altCtrl.text = newAlt;
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
    if (v.trim().isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return 'მხოლოდ რიცხვი';
    if (n < -90 || n > 90) return '-90 … 90';
    return null;
  }

  String? _validateLon(String v) {
    if (v.trim().isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return 'მხოლოდ რიცხვი';
    if (n < -180 || n > 180) return '-180 … 180';
    return null;
  }

  String? _validateAlt(String v) {
    if (v.trim().isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return 'მხოლოდ რიცხვი';
    if (n < -500 || n > 9000) return '−500 … 9000 მ';
    return null;
  }

  String? _validateAspect(String v) {
    if (v.trim().isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return 'მხოლოდ რიცხვი';
    if (n < 0 || n > 360) return '0 … 360°';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'ბუნებრივ-ტერიტორიული კომპლექსის (ბტკ) აღწერა'),
          const SizedBox(height: 4),
          Text('ID: ${r.id}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),

          // Date
          TextField(
            controller: _dateCtrl,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'თარიღი',
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

          // Location
          TextField(
            controller: _locationCtrl,
            onChanged: (v) => widget.onChanged(r..location = v),
            decoration: const InputDecoration(
              labelText: 'ადგილმდებარეობა',
              hintText: 'მდებარეობის სახელი / აღწერა',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          Text('კოორდინატები', style: Theme.of(context).textTheme.labelLarge),
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
                      widget.onChanged(r..latitude = double.tryParse(v));
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'განედი (lat)',
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
                      widget.onChanged(r..longitude = double.tryParse(v));
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'გრძედი (lon)',
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
                    labelText: 'სიმაღლე (მ)',
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
                    labelText: 'ასპექტი (°)',
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
            label: const Text('GPS-ით დადგენა'),
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
