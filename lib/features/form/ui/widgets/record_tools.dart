import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/services/template_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/btk_record.dart';
import '../../../../models/record_quality.dart';
import '../../../../models/record_template.dart';

String sectionLabel(AppLocalizations l10n, FormSection section) {
  switch (section) {
    case FormSection.basic:
      return l10n.tabBasic;
    case FormSection.physGeo:
      return l10n.tabPhysGeo;
    case FormSection.vegetation:
      return l10n.tabVegetation;
    case FormSection.soil:
      return l10n.soil;
    case FormSection.geomass:
      return l10n.tabGeomass;
    case FormSection.vertStruct:
      return l10n.tabVertStruct;
  }
}

/// Date and time down to the minute, in the app's usual date order.
String editedStamp(DateTime d) => d.toString().substring(0, 16);

/// Lists what to check in [record]. Returns the section to open, if one is chosen.
Future<FormSection?> showQualitySheet(BuildContext context, BtkRecord record) {
  final l10n = AppLocalizations.of(context)!;
  final notes = record.qualityNotes();
  return showModalBottomSheet<FormSection>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l10n.qualityTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(l10n.lastEdited(editedStamp(record.updatedAt))),
            ),
            if (notes.isEmpty)
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text(l10n.qualityNoNotes),
              ),
            for (final n in notes)
              ListTile(
                dense: true,
                leading: const Icon(Icons.error_outline, color: Color(0xFFE65100)),
                title: Text(n.message(l10n)),
                subtitle: Text(sectionLabel(l10n, n.section)),
                onTap: () => Navigator.pop(ctx, n.section),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Asks which sections to use, with [initial] already ticked.
Future<Set<FormSection>?> _pickSections(
  BuildContext context, {
  required String title,
  required String action,
  String? note,
  required Set<FormSection> initial,
  TextEditingController? nameCtrl,
}) {
  final l10n = AppLocalizations.of(context)!;
  final chosen = {...initial};
  return showDialog<Set<FormSection>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (nameCtrl != null)
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l10n.templateName),
                ),
              if (note != null) Text(note, style: const TextStyle(fontSize: 13)),
              for (final s in reusableSections)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: chosen.contains(s),
                  title: Text(sectionLabel(l10n, s)),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      chosen.add(s);
                    } else {
                      chosen.remove(s);
                    }
                  }),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, chosen),
            child: Text(action),
          ),
        ],
      ),
    ),
  );
}

/// Measured values belong to one site, so they start unticked when reusing.
const _defaultSections = {
  FormSection.physGeo,
  FormSection.vegetation,
  FormSection.soil,
  FormSection.vertStruct,
};

/// Saves parts of [record] as a named template. Throws if the write fails.
Future<bool> saveAsTemplate(BuildContext context, BtkRecord record) async {
  final l10n = AppLocalizations.of(context)!;
  final nameCtrl = TextEditingController();
  try {
    final sections = await _pickSections(
      context,
      title: l10n.recordSaveAsTemplate,
      action: l10n.save,
      initial: _defaultSections,
      nameCtrl: nameCtrl,
    );
    final name = nameCtrl.text.trim();
    if (sections == null || sections.isEmpty) return false;
    await TemplateService.add(RecordTemplate.fromRecord(
      id: const Uuid().v4().substring(0, 8),
      name: name.isEmpty ? l10n.templateDefaultName(editedStamp(DateTime.now())) : name,
      from: record,
      sections: sections,
    ));
    return true;
  } finally {
    nameCtrl.dispose();
  }
}

/// Lets the user pick a template or another record and fills the empty parts of
/// [target]. Returns the number filled, or null if the user backed out.
Future<int?> fillFromOther(
    BuildContext context, BtkRecord target, List<BtkRecord> allRecords) async {
  final l10n = AppLocalizations.of(context)!;
  var templates = await TemplateService.load();
  if (!context.mounted) return null;

  final recent = allRecords.where((r) => r.id != target.id).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  final source = await showModalBottomSheet<BtkRecord>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: [
              if (templates.isEmpty && recent.isEmpty)
                ListTile(title: Text(l10n.nothingToReuse)),
              if (templates.isNotEmpty)
                ListTile(
                    dense: true,
                    title: Text(l10n.templates,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
              for (final t in templates)
                ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: Text(t.name),
                  onTap: () => Navigator.pop(ctx, t.content),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: l10n.deleteTemplate,
                    onPressed: () async {
                      await TemplateService.delete(t.id);
                      final left = await TemplateService.load();
                      setState(() => templates = left);
                    },
                  ),
                ),
              if (recent.isNotEmpty)
                ListTile(
                    dense: true,
                    title: Text(l10n.recentRecords,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
              for (final r in recent.take(10))
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(r.name.isNotEmpty ? r.name : l10n.btkNumber(r.id)),
                  subtitle: Text(r.location.isNotEmpty
                      ? r.location
                      : editedStamp(r.updatedAt)),
                  onTap: () => Navigator.pop(ctx, r),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  final sections = await _pickSections(
    context,
    title: l10n.fillFromOther,
    action: l10n.fillAction,
    note: l10n.fillOnlyEmpty,
    initial: _defaultSections,
  );
  if (sections == null) return null;
  return fillEmptyParts(target, source, sections);
}
