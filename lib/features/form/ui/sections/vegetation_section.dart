import 'package:flutter/material.dart';
import '../../../../models/btk_record.dart';

class VegetationSection extends StatefulWidget {
  final BtkRecord record;
  final ValueChanged<BtkRecord> onChanged;

  const VegetationSection({super.key, required this.record, required this.onChanged});

  @override
  State<VegetationSection> createState() => _VegetationSectionState();
}

class _VegetationSectionState extends State<VegetationSection> {
  late List<List<TextEditingController>> _ctrls;

  List<TextEditingController> _makeRowCtrls(VegetationRow r) => [
        TextEditingController(text: r.tier),
        TextEditingController(text: r.height),
        TextEditingController(text: r.density),
        TextEditingController(text: r.phenophase),
        TextEditingController(text: r.species),
      ];

  @override
  void initState() {
    super.initState();
    _ctrls = widget.record.vegetation.map(_makeRowCtrls).toList();
  }

  @override
  void dispose() {
    for (final row in _ctrls) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _addRow() {
    final newRow = VegetationRow();
    setState(() {
      widget.record.vegetation.add(newRow);
      _ctrls.add(_makeRowCtrls(newRow));
    });
    widget.onChanged(widget.record);
  }

  void _removeRow(int i) {
    if (widget.record.vegetation.length <= 1) return;
    for (final c in _ctrls[i]) {
      c.dispose();
    }
    setState(() {
      widget.record.vegetation.removeAt(i);
      _ctrls.removeAt(i);
    });
    widget.onChanged(widget.record);
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.record.vegetation;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, 'მცენარეულობა'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)),
              columnSpacing: 12,
              columns: const [
                DataColumn(label: Text('იარ.', style: TextStyle(fontSize: 12))),
                DataColumn(label: Text('სიმ. (მ)', style: TextStyle(fontSize: 12))),
                DataColumn(label: Text('სიმძლ.', style: TextStyle(fontSize: 12))),
                DataColumn(label: Text('ფენოფ.', style: TextStyle(fontSize: 12))),
                DataColumn(label: Text('სახეობა', style: TextStyle(fontSize: 12))),
                DataColumn(label: Text('', style: TextStyle(fontSize: 12))),
              ],
              rows: List.generate(rows.length, (i) {
                final r = rows[i];
                final cs = _ctrls[i];
                return DataRow(cells: [
                  DataCell(_tcell(cs[0], (v) => r.tier = v)),
                  DataCell(_tcell(cs[1], (v) => r.height = v)),
                  DataCell(_tcell(cs[2], (v) => r.density = v)),
                  DataCell(_tcell(cs[3], (v) => r.phenophase = v)),
                  DataCell(_tcell(cs[4], (v) => r.species = v, wide: true)),
                  DataCell(IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                    onPressed: () => _removeRow(i),
                  )),
                ]);
              }),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add),
            label: const Text('სტრიქონის დამატება'),
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

Widget _tcell(TextEditingController ctrl, ValueChanged<String> onChanged,
        {bool wide = false}) =>
    SizedBox(
      width: wide ? 120 : 70,
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),
      ),
    );
