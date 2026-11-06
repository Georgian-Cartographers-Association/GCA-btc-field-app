import 'package:flutter/material.dart';

/// The English copy of a text field, for records filled in both languages.
/// Clearing it removes the entry, so an empty English text isn't stored.
class EnglishField extends StatefulWidget {
  final Map<String, String> values;
  final String fieldKey;
  final String label;
  final int maxLines;
  final bool dense;
  final VoidCallback onChanged;

  const EnglishField({
    super.key,
    required this.values,
    required this.fieldKey,
    required this.label,
    required this.onChanged,
    this.maxLines = 1,
    this.dense = false,
  });

  @override
  State<EnglishField> createState() => _EnglishFieldState();
}

class _EnglishFieldState extends State<EnglishField> {
  late final _ctrl = TextEditingController(text: widget.values[widget.fieldKey] ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: widget.dense ? 4 : 8),
      child: TextField(
        controller: _ctrl,
        maxLines: widget.maxLines,
        style: widget.dense ? const TextStyle(fontSize: 12) : null,
        onChanged: (v) {
          if (v.trim().isEmpty) {
            widget.values.remove(widget.fieldKey);
          } else {
            widget.values[widget.fieldKey] = v;
          }
          widget.onChanged();
        },
        decoration: InputDecoration(
          labelText: widget.label.isEmpty ? 'EN' : '${widget.label} · EN',
          prefixIcon: widget.dense ? null : const Icon(Icons.translate, size: 18),
          border: widget.dense ? const UnderlineInputBorder() : const OutlineInputBorder(),
          contentPadding: widget.dense
              ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
      ),
    );
  }
}
