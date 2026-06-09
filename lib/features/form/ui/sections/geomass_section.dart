import 'package:flutter/material.dart';
import '../../../../models/btk_record.dart';

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, 'გეომასების კვლევა — ბტკ-ის ვ.პ. მიწისზედა ნაწ.'),
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
              columns: const [
                DataColumn(label: Text('სექ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('სიღ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('პედ.მოც.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('პედ.რ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ლით.რ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ლით.სმ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ჰიდ.რ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ჰიდ.სვ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ჰიდ.მშ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ფიტ.სვ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('ფიტ.მშ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('', style: TextStyle(fontSize: 11))),
              ],
              rows: List.generate(widget.record.geomasses.length, (i) {
                final g = widget.record.geomasses[i];
                final cs = _geoCtrls[i];
                return DataRow(cells: [
                  DataCell(_gcell(cs[0], (v) => g.section = v)),
                  DataCell(_gcell(cs[1], (v) => g.depth = v)),
                  DataCell(_gcell(cs[2], (v) => g.pedomassBulk = v)),
                  DataCell(_gcell(cs[3], (v) => g.pedomassQty = v)),
                  DataCell(_gcell(cs[4], (v) => g.lithomassQty = v)),
                  DataCell(_gcell(cs[5], (v) => g.lithomassDensity = v)),
                  DataCell(_gcell(cs[6], (v) => g.hydromassQty = v)),
                  DataCell(_gcell(cs[7], (v) => g.hydromassWet = v)),
                  DataCell(_gcell(cs[8], (v) => g.hydromassDry = v)),
                  DataCell(_gcell(cs[9], (v) => g.phytomassWet = v)),
                  DataCell(_gcell(cs[10], (v) => g.phytomassDry = v)),
                  DataCell(IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 16, color: Colors.red),
                    onPressed: () => _removeRow(i),
                  )),
                ]);
              }),
            ),
          ),
          TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add),
              label: const Text('სტრიქ.')),
          const SizedBox(height: 20),
          _header(context, 'ხე-მცენარეების ფიტომასა (ტ/ჰა)'),
          const SizedBox(height: 8),
          TextField(
            controller: _expPlotSizeCtrl,
            onChanged: (v) {
              widget.record.experimentPlotSize = v;
              widget.onChanged(widget.record);
            },
            decoration: const InputDecoration(
              labelText: 'ექსპ. ნაკვ. ზომა',
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
              columns: const [
                DataColumn(label: Text('სახ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('მ.წ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('სვ.მ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('სვ.ფ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('სვ.ტ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('სვ.ფეს.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('სვ.ჯ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('მშ.მ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('მშ.ფ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('მშ.ტ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('მშ.ფეს.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('მშ.ჯ.', style: TextStyle(fontSize: 11))),
                DataColumn(label: Text('', style: TextStyle(fontSize: 11))),
              ],
              rows: List.generate(widget.record.treePhytomass.length, (i) {
                final t = widget.record.treePhytomass[i];
                final cs = _treeCtrls[i];
                return DataRow(cells: [
                  DataCell(_gcell(cs[0], (v) => t.species = v, wide: true)),
                  DataCell(_gcell(cs[1], (v) => t.bulkDensity = v)),
                  DataCell(_gcell(cs[2], (v) => t.wetWood = v)),
                  DataCell(_gcell(cs[3], (v) => t.wetLeaves = v)),
                  DataCell(_gcell(cs[4], (v) => t.wetBranches = v)),
                  DataCell(_gcell(cs[5], (v) => t.wetRoots = v)),
                  DataCell(_gcell(cs[6], (v) => t.wetTotal = v)),
                  DataCell(_gcell(cs[7], (v) => t.dryWood = v)),
                  DataCell(_gcell(cs[8], (v) => t.dryLeaves = v)),
                  DataCell(_gcell(cs[9], (v) => t.dryBranches = v)),
                  DataCell(_gcell(cs[10], (v) => t.dryRoots = v)),
                  DataCell(_gcell(cs[11], (v) => t.dryTotal = v)),
                  DataCell(IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 16, color: Colors.red),
                    onPressed: () => _removeTree(i),
                  )),
                ]);
              }),
            ),
          ),
          TextButton.icon(
              onPressed: _addTree,
              icon: const Icon(Icons.add),
              label: const Text('ხე-მც. სტრიქ.')),
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

Widget _gcell(TextEditingController ctrl, ValueChanged<String> onChanged,
        {bool wide = false}) =>
    SizedBox(
      width: wide ? 90 : 55,
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 11),
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        ),
      ),
    );
