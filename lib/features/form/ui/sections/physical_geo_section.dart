import 'package:flutter/material.dart';
import '../../../../models/btk_record.dart';
import '../widgets/english_field.dart';
import '../../../../l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final r = widget.record;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, l10n.physGeoDesc),
          const SizedBox(height: 16),
          TextField(
            controller: _geologicalFormationCtrl,
            onChanged: (v) => widget.onChanged(r..geologicalFormation = v),
            decoration: InputDecoration(
              labelText: l10n.geologicalFormation,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          if (r.isBilingual)
            EnglishField(
              values: r.english,
              fieldKey: 'geologicalFormation',
              label: l10n.geologicalFormation,
              onChanged: () => widget.onChanged(r),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _reliefTypeCtrl,
            onChanged: (v) => widget.onChanged(r..reliefType = v),
            decoration: InputDecoration(
              labelText: l10n.reliefType,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          if (r.isBilingual)
            EnglishField(
              values: r.english,
              fieldKey: 'reliefType',
              label: l10n.reliefType,
              onChanged: () => widget.onChanged(r),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _morphologicalDescCtrl,
            onChanged: (v) => widget.onChanged(r..morphologicalDesc = v),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.morphologicalDesc,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          if (r.isBilingual)
            EnglishField(
              values: r.english,
              fieldKey: 'morphologicalDesc',
              label: l10n.morphologicalDesc,
              maxLines: 3,
              onChanged: () => widget.onChanged(r),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _geomorphProcessesCtrl,
            onChanged: (v) => widget.onChanged(r..geomorphProcesses = v),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.geomorphProcesses,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          if (r.isBilingual)
            EnglishField(
              values: r.english,
              fieldKey: 'geomorphProcesses',
              label: l10n.geomorphProcesses,
              maxLines: 2,
              onChanged: () => widget.onChanged(r),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _migrationRegimeCtrl,
            onChanged: (v) => widget.onChanged(r..migrationRegime = v),
            decoration: InputDecoration(
              labelText: l10n.migrationRegime,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          if (r.isBilingual)
            EnglishField(
              values: r.english,
              fieldKey: 'migrationRegime',
              label: l10n.migrationRegime,
              onChanged: () => widget.onChanged(r),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _moistureDegreeCtrl,
            onChanged: (v) => widget.onChanged(r..moistureDegree = v),
            decoration: InputDecoration(
              labelText: l10n.moistureDegree,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          if (r.isBilingual)
            EnglishField(
              values: r.english,
              fieldKey: 'moistureDegree',
              label: l10n.moistureDegree,
              onChanged: () => widget.onChanged(r),
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
