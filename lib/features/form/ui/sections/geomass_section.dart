import 'package:flutter/material.dart';
import '../../../../models/btk_record.dart';
import '../../../../models/measure.dart';
import '../widgets/measure_text_field.dart';
import '../../../../l10n/generated/app_localizations.dart';

class GeomassSection extends StatefulWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;

  const GeomassSection({super.key, required this.record, required this.onChanged});

  @override
  State<GeomassSection> createState() => _GeomassSectionState();
}

class _GeomassSectionState extends State<GeomassSection> {
  late final TextEditingController _expPlotSizeCtrl;
  late List<List<TextEditingController>> _geoCtrls;
  late List<List<TextEditingController>> _treeCtrls;

  // GeomassRow fields: section, depth, pedomassBulk, pedomassQty,
  // lithomassQty, lithomassDensity, hydromassQty, hydromassWet, hydromassDry,
  // phytomassWet, phytomassDry  (indices 0–10)
  List<TextEditingController> _makeGeoCtrls(GeomassRow g) => [
        TextEditingController(text: g.section),
        TextEditingController(text: g.depth),
        TextEditingController(text: g.pedomassBulk),
        TextEditingController(text: g.pedomassQty),
        TextEditingController(text: g.lithomassQty),
        TextEditingController(text: g.lithomassDensity),
        TextEditingController(text: g.hydromassQty),
        TextEditingController(text: g.hydromassWet),
        TextEditingController(text: g.hydromassDry),
        TextEditingController(text: g.phytomassWet),
        TextEditingController(text: g.phytomassDry),
      ];

  // TreePhytomassRow fields: species, bulkDensity, wetWood, wetLeaves,
  // wetBranches, wetRoots, wetTotal, dryWood, dryLeaves, dryBranches,
  // dryRoots, dryTotal  (indices 0–11)
  List<TextEditingController> _makeTreeCtrls(TreePhytomassRow t) => [
        TextEditingController(text: t.species),
        TextEditingController(text: t.bulkDensity),
        TextEditingController(text: t.wetWood),
        TextEditingController(text: t.wetLeaves),
        TextEditingController(text: t.wetBranches),
        TextEditingController(text: t.wetRoots),
        TextEditingController(text: t.wetTotal),
        TextEditingController(text: t.dryWood),
        TextEditingController(text: t.dryLeaves),
        TextEditingController(text: t.dryBranches),
        TextEditingController(text: t.dryRoots),
        TextEditingController(text: t.dryTotal),
      ];

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _expPlotSizeCtrl = TextEditingController(text: r.experimentPlotSize);
    _geoCtrls = r.geomasses.map(_makeGeoCtrls).toList();
    _treeCtrls = r.treePhytomass.map(_makeTreeCtrls).toList();
  }

  @override
  void dispose() {
    _expPlotSizeCtrl.dispose();
    for (final row in _geoCtrls) {
      for (final c in row) {
        c.dispose();
      }
    }
    for (final row in _treeCtrls) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _addRow() {
    final newRow = GeomassRow();
    setState(() {
      widget.record.geomasses.add(newRow);
      _geoCtrls.add(_makeGeoCtrls(newRow));
    });
    widget.onChanged(widget.record);
  }

  void _removeRow(int i) {
    if (widget.record.geomasses.length <= 1) return;
    for (final c in _geoCtrls[i]) {
      c.dispose();
    }
    setState(() {
      widget.record.geomasses.removeAt(i);
      _geoCtrls.removeAt(i);
    });
    widget.onChanged(widget.record);
  }

  void _addTree() {
    final newRow = TreePhytomassRow();
    setState(() {
      widget.record.treePhytomass.add(newRow);
      _treeCtrls.add(_makeTreeCtrls(newRow));
    });
    widget.onChanged(widget.record);
  }

  void _removeTree(int i) {
    if (widget.record.treePhytomass.length <= 1) return;
    for (final c in _treeCtrls[i]) {
      c.dispose();
    }
    setState(() {
      widget.record.treePhytomass.removeAt(i);
      _treeCtrls.removeAt(i);
    });
    widget.onChanged(widget.record);
  }

  // A table cell edits its row in place, so it must report the change itself or
  // the edit gets no autosave and no unsaved-changes warning.
  ValueChanged<String> _edit(void Function(String) set) => (v) {
        set(v);
        widget.onChanged(widget.record);
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, l10n.geomassHeader),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5)),
              columnSpacing: 8,
              columns: [
                DataColumn(label: Text(l10n.gmSection, style: TextStyle(fontSize: 11))),
                DataColumn(label: Text(l10n.gmDepth, style: TextStyle(fontSize: 11))),
                DataColumn(label: _withUnit(l10n.gmPedBulk, l10n.unitGCm3)),
                DataColumn(label: _withUnit(l10n.gmPedQty, l10n.unitTHa)),
                DataColumn(label: _withUnit(l10n.gmLithQty, l10n.unitTHa)),
                DataColumn(label: _withUnit(l10n.gmLithDens, l10n.unitGCm3)),
                DataColumn(label: _withUnit(l10n.gmHydQty, l10n.unitTHa)),
                DataColumn(label: Text(l10n.gmHydWet, style: TextStyle(fontSize: 11))),
                DataColumn(label: Text(l10n.gmHydDry, style: TextStyle(fontSize: 11))),
                DataColumn(label: _withUnit(l10n.gmPhytWet, l10n.unitTHa)),
                DataColumn(label: _withUnit(l10n.gmPhytDry, l10n.unitTHa)),
                DataColumn(label: Text('', style: TextStyle(fontSize: 11))),
              ],
              rows: List.generate(widget.record.geomasses.length, (i) {
                final g = widget.record.geomasses[i];
                final cs = _geoCtrls[i];
                return DataRow(cells: [
                  DataCell(_gcell(cs[0], _edit((v) => g.section = v))),
                  DataCell(_gcell(cs[1], _edit((v) => g.depth = v), spec: Measures.depth)),
                  DataCell(_gcell(cs[2], _edit((v) => g.pedomassBulk = v), spec: Measures.soilBulkDensity)),
                  DataCell(_gcell(cs[3], _edit((v) => g.pedomassQty = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[4], _edit((v) => g.lithomassQty = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[5], _edit((v) => g.lithomassDensity = v), spec: Measures.rockDensity)),
                  DataCell(_gcell(cs[6], _edit((v) => g.hydromassQty = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[7], _edit((v) => g.hydromassWet = v), spec: Measures.plain)),
                  DataCell(_gcell(cs[8], _edit((v) => g.hydromassDry = v), spec: Measures.plain)),
                  DataCell(_gcell(cs[9], _edit((v) => g.phytomassWet = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[10], _edit((v) => g.phytomassDry = v), spec: Measures.geomass)),
                  DataCell(IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 16, color: Colors.red),
                    onPressed: () => _removeRow(i),
                  )),
                ]);
              }),
            ),
          ),
          const MeasureLegend(),
          TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add),
              label: Text(l10n.rowShort)),
          const SizedBox(height: 20),
          _header(context, l10n.treePhytomassHeader),
          const SizedBox(height: 8),
          MeasureTextField(
            controller: _expPlotSizeCtrl,
            spec: Measures.plotSize,
            onChanged: (v) {
              widget.record.experimentPlotSize = v;
              widget.onChanged(widget.record);
            },
            decoration: InputDecoration(
              labelText: l10n.experimentPlotSize,
              hintText: '50x100',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5)),
              columnSpacing: 8,
              columns: [
                DataColumn(label: Text(l10n.tpSpecies, style: TextStyle(fontSize: 11))),
                DataColumn(label: _withUnit(l10n.tpVolume, l10n.unitTM3)),
                DataColumn(label: _withUnit(l10n.tpWetWood, l10n.unitTHa)),
                DataColumn(label: _withUnit(l10n.tpWetLeaves, l10n.unitTHa)),
                DataColumn(label: _withUnit(l10n.tpWetBranches, l10n.unitTHa)),
                DataColumn(label: _withUnit(l10n.tpWetRoots, l10n.unitTHa)),
                DataColumn(label: _withUnit(l10n.tpWetTotal, l10n.unitTHa)),
                DataColumn(label: _withUnit(l10n.tpDryWood, l10n.unitTHa)),
                DataColumn(label: _withUnit(l10n.tpDryLeaves, l10n.unitTHa)),
                DataColumn(label: _withUnit(l10n.tpDryBranches, l10n.unitTHa)),
                DataColumn(label: _withUnit(l10n.tpDryRoots, l10n.unitTHa)),
                DataColumn(label: _withUnit(l10n.tpDryTotal, l10n.unitTHa)),
                DataColumn(label: Text('', style: TextStyle(fontSize: 11))),
              ],
              rows: List.generate(widget.record.treePhytomass.length, (i) {
                final t = widget.record.treePhytomass[i];
                final cs = _treeCtrls[i];
                return DataRow(cells: [
                  DataCell(_gcell(cs[0], _edit((v) => t.species = v), wide: true)),
                  DataCell(_gcell(cs[1], _edit((v) => t.bulkDensity = v), spec: Measures.woodDensity)),
                  DataCell(_gcell(cs[2], _edit((v) => t.wetWood = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[3], _edit((v) => t.wetLeaves = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[4], _edit((v) => t.wetBranches = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[5], _edit((v) => t.wetRoots = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[6], _edit((v) => t.wetTotal = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[7], _edit((v) => t.dryWood = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[8], _edit((v) => t.dryLeaves = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[9], _edit((v) => t.dryBranches = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[10], _edit((v) => t.dryRoots = v), spec: Measures.geomass)),
                  DataCell(_gcell(cs[11], _edit((v) => t.dryTotal = v), spec: Measures.geomass)),
                  DataCell(IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 16, color: Colors.red),
                    onPressed: () => _removeTree(i),
                  )),
                ]);
              }),
            ),
          ),
          const MeasureLegend(),
          TextButton.icon(
              onPressed: _addTree,
              icon: const Icon(Icons.add),
              label: Text(l10n.treeRowShort)),
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

Widget _withUnit(String label, String unit) =>
    Text('$label\n$unit', style: const TextStyle(fontSize: 11));

Widget _gcell(TextEditingController ctrl, ValueChanged<String> onChanged,
    {bool wide = false, MeasureSpec? spec}) {
  const style = TextStyle(fontSize: 11);
  const decoration = InputDecoration(
    border: UnderlineInputBorder(),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
  );
  return SizedBox(
    width: wide ? 90 : 55,
    child: spec == null
        ? TextField(
            controller: ctrl,
            onChanged: onChanged,
            style: style,
            decoration: decoration,
          )
        : MeasureTextField(
            controller: ctrl,
            spec: spec,
            onChanged: onChanged,
            style: style,
            decoration: decoration,
          ),
  );
}
