import 'package:flutter/material.dart';
import '../../../../models/btk_record.dart';

class PhysicalGeoSection extends StatefulWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;

  const PhysicalGeoSection({super.key, required this.record, required this.onChanged});

  @override
  State<PhysicalGeoSection> createState() => _PhysicalGeoSectionState();
}

class _PhysicalGeoSectionState extends State<PhysicalGeoSection> {
  late final TextEditingController _geologicalFormationCtrl;
  late final TextEditingController _reliefTypeCtrl;
  late final TextEditingController _morphologicalDescCtrl;
  late final TextEditingController _geomorphProcessesCtrl;
  late final TextEditingController _migrationRegimeCtrl;
  late final TextEditingController _moistureDegreeCtrl;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _geologicalFormationCtrl = TextEditingController(text: r.geologicalFormation);
    _reliefTypeCtrl = TextEditingController(text: r.reliefType);
    _morphologicalDescCtrl = TextEditingController(text: r.morphologicalDesc);
    _geomorphProcessesCtrl = TextEditingController(text: r.geomorphProcesses);
    _migrationRegimeCtrl = TextEditingController(text: r.migrationRegime);
    _moistureDegreeCtrl = TextEditingController(text: r.moistureDegree);
  }

  @override
  void dispose() {
    _geologicalFormationCtrl.dispose();
    _reliefTypeCtrl.dispose();
    _morphologicalDescCtrl.dispose();
    _geomorphProcessesCtrl.dispose();
    _migrationRegimeCtrl.dispose();
    _moistureDegreeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, 'ფიზიკურ-გეოგრაფიული დახასიათება'),
          const SizedBox(height: 16),
          TextField(
            controller: _geologicalFormationCtrl,
            onChanged: (v) => widget.onChanged(r..geologicalFormation = v),
            decoration: const InputDecoration(
              labelText: 'გეოლოგიური ფორმაცია',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reliefTypeCtrl,
            onChanged: (v) => widget.onChanged(r..reliefType = v),
            decoration: const InputDecoration(
              labelText: 'რელიეფის ტიპი',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _morphologicalDescCtrl,
            onChanged: (v) => widget.onChanged(r..morphologicalDesc = v),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'მორფოლოგიური დახასიათება',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _geomorphProcessesCtrl,
            onChanged: (v) => widget.onChanged(r..geomorphProcesses = v),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'თანამედროვე გეომორფოლოგიური პროცესები',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _migrationRegimeCtrl,
            onChanged: (v) => widget.onChanged(r..migrationRegime = v),
            decoration: const InputDecoration(
              labelText: 'მიგრაციის რეჟიმი',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _moistureDegreeCtrl,
            onChanged: (v) => widget.onChanged(r..moistureDegree = v),
            decoration: const InputDecoration(
              labelText: 'დატენიანების ხარისხი',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _header(BuildContext context, String title) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer)),
    );
