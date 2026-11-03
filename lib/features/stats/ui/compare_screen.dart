import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/btk_record.dart';
import '../../../models/record_quality.dart';
import '../../form/ui/widgets/record_tools.dart' show sectionLabel;
import '../domain/record_comparison.dart';

const _labelWidth = 135.0;
const _valueWidth = 120.0;

/// Puts [records] side by side, one column each.
class CompareScreen extends StatefulWidget {
  final List<BtkRecord> records;

  const CompareScreen({super.key, required this.records});

  static Future<void> open(BuildContext context, List<BtkRecord> records) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => CompareScreen(records: records),
      ));

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late final List<CompareRow> _rows = compareRecords(widget.records);
  bool _onlyDifferences = false;

  Widget _cell(String? text, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          text ?? '—',
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      );

  List<TableRow> _tableRows(AppLocalizations l10n, ColorScheme cs) {
    final extraCells = widget.records.length;
    TableRow titleRow(String title) => TableRow(
          decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.5)),
          children: [
            _cell(title, bold: true),
            for (var i = 0; i < extraCells; i++) const SizedBox.shrink(),
          ],
        );

    final rows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHighest),
        children: [
          const SizedBox.shrink(),
          for (final r in widget.records)
            _cell(r.name.isNotEmpty ? r.name : l10n.btkNumber(r.id), bold: true),
        ],
      ),
    ];

    FormSection? current;
    for (final row in _rows) {
      if (_onlyDifferences && !row.differs) continue;
      if (row.section != current) {
        current = row.section;
        rows.add(titleRow(sectionLabel(l10n, row.section)));
      }
      rows.add(TableRow(children: [
        _cell(row.label(l10n), color: cs.onSurfaceVariant),
        for (final v in row.values)
          _cell(v, color: v == compareUnreadable ? const Color(0xFFE65100) : null),
      ]));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tableRows = _tableRows(l10n, cs);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.compareTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SwitchListTile(
            title: Text(l10n.compareOnlyDifferences),
            value: _onlyDifferences,
            onChanged: (v) => setState(() => _onlyDifferences = v),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(_valueWidth),
              columnWidths: const {0: FixedColumnWidth(_labelWidth)},
              border: TableBorder.symmetric(
                inside: BorderSide(color: cs.outlineVariant, width: 0.5),
              ),
              children: tableRows,
            ),
          ),
          // Only the record names are left when nothing differs.
          if (tableRows.length == 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.compareNoDifferences, textAlign: TextAlign.center),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.compareLegend,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
