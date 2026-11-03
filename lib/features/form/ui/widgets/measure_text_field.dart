import 'package:flutter/material.dart';
import '../../../../models/measure.dart';
import '../../../../l10n/generated/app_localizations.dart';

const _warningColor = Color(0xFFE65100);

/// A text field for a measured value. An odd value turns orange and is still
/// saved as typed, so a field note is never lost to validation.
class MeasureTextField extends StatelessWidget {
  final TextEditingController controller;
  final MeasureSpec spec;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final TextStyle? style;

  const MeasureTextField({
    super.key,
    required this.controller,
    required this.spec,
    required this.onChanged,
    required this.decoration,
    this.style,
  });

  InputDecoration _warning(InputBorder? like) {
    const side = BorderSide(color: _warningColor, width: 1.5);
    final border = like is OutlineInputBorder
        ? const OutlineInputBorder(borderSide: side)
        : const UnderlineInputBorder(borderSide: side);
    return decoration.copyWith(enabledBorder: border, focusedBorder: border);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final issue = spec.check(value.text);
        final field = TextField(
          controller: controller,
          onChanged: onChanged,
          style: style,
          // A range or a plot size needs a separator the number pad may not have.
          keyboardType: spec.kind == MeasureKind.number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration:
              issue == null ? decoration : _warning(decoration.border),
        );
        if (issue == null) return field;
        return Tooltip(
          message: issue == MeasureIssue.unreadable
              ? l10n.measureUnreadable
              : l10n.measureOutOfRange,
          child: field,
        );
      },
    );
  }
}

/// Explains the orange values, placed under a table of measured values.
class MeasureLegend extends StatelessWidget {
  const MeasureLegend({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          AppLocalizations.of(context)!.measureLegend,
          style: const TextStyle(fontSize: 11, color: _warningColor),
        ),
      );
}
