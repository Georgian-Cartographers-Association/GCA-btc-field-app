// Numeric reading of the form's measured values.
//
// The typed text stays the stored value: the field sheet has entries such as
// "0,5", "16-32 მ" and "50X100 მ2", and old records may hold anything. Numbers
// are read from it when needed, and an odd value only gets a warning.

const _number = r'(\d*[.,]?\d+)';
final _numberOnly = RegExp('^$_number\$');
final _rangeOnly = RegExp('^$_number\\s*[-–—]\\s*$_number\$');
final _plotOnly = RegExp('^$_number\\s*[xX×*ხ]\\s*$_number\$');

double? _toDouble(String s) => double.tryParse(s.replaceFirst(',', '.'));

class MeasureRange {
  final double from;
  final double to;

  const MeasureRange(this.from, this.to);
}

enum MeasureKind { number, range, plotSize }

enum MeasureIssue { unreadable, outOfRange }

class MeasureSpec {
  final MeasureKind kind;

  /// Spellings of the field's own unit allowed after the number, longest
  /// first. A different unit counts as unreadable, because nothing is converted.
  final List<String> units;
  final double min;
  final double? max;

  const MeasureSpec({
    this.kind = MeasureKind.number,
    this.units = const [],
    this.min = 0,
    this.max,
  });

  String _bare(String text) {
    final t = text.trim();
    for (final u in units) {
      if (t.endsWith(u)) {
        return t.substring(0, t.length - u.length).trim();
      }
    }
    return t;
  }

  /// The value of a single number, or null when [text] isn't one.
  double? value(String text) {
    final m = _numberOnly.firstMatch(_bare(text));
    return m == null ? null : _toDouble(m[1]!);
  }

  /// A range such as "10-20", where one number is a range of zero width.
  MeasureRange? range(String text) {
    final bare = _bare(text);
    final m = _rangeOnly.firstMatch(bare);
    if (m != null) return MeasureRange(_toDouble(m[1]!)!, _toDouble(m[2]!)!);
    final single = _numberOnly.firstMatch(bare);
    if (single == null) return null;
    final v = _toDouble(single[1]!)!;
    return MeasureRange(v, v);
  }

  /// The area of a plot written as "50X100" or as the area itself.
  double? area(String text) {
    final bare = _bare(text);
    final m = _plotOnly.firstMatch(bare);
    if (m != null) return _toDouble(m[1]!)! * _toDouble(m[2]!)!;
    final single = _numberOnly.firstMatch(bare);
    return single == null ? null : _toDouble(single[1]!);
  }

  bool _inBounds(double v) => v >= min && (max == null || v <= max!);

  /// What is odd about [text]. Empty is fine, since any field may be unfilled.
  MeasureIssue? check(String text) {
    if (text.trim().isEmpty) return null;
    switch (kind) {
      case MeasureKind.number:
        final v = value(text);
        if (v == null) return MeasureIssue.unreadable;
        return _inBounds(v) ? null : MeasureIssue.outOfRange;
      case MeasureKind.range:
        final r = range(text);
        if (r == null) return MeasureIssue.unreadable;
        return _inBounds(r.from) && _inBounds(r.to) && r.from <= r.to
            ? null
            : MeasureIssue.outOfRange;
      case MeasureKind.plotSize:
        final a = area(text);
        if (a == null) return MeasureIssue.unreadable;
        return a > 0 ? null : MeasureIssue.outOfRange;
    }
  }
}

const _metres = ['მეტრი', 'მ.', 'მ', 'm'];
const _gPerCm3 = ['გრ/სმ³', 'გრ/სმ3', 'გ/სმ³', 'გ/სმ3', 'g/cm³', 'g/cm3'];
const _tPerHa = ['ტ/ჰა', 't/ha'];
const _tPerM3 = ['ტ/მ³', 'ტ/მ3', 't/m³', 't/m3'];

/// Units and limits follow the methodology (sections 1.6.2 to 1.6.5, and the
/// field sheet). Limits are wide on purpose: they catch typing slips such as a
/// misplaced decimal point, and they never stop a value from being saved.
class Measures {
  Measures._();

  /// Mean height of a species, in metres.
  static const vegHeight = MeasureSpec(units: _metres, max: 120);

  /// Height of the above-ground part, such as "16-32 მ".
  static const vertHeight =
      MeasureSpec(kind: MeasureKind.range, units: _metres, max: 150);

  /// Plot size in metres, such as "50X100 მ2".
  static const plotSize = MeasureSpec(
    kind: MeasureKind.plotSize,
    units: ['მ²', 'მ2', 'm²', 'm2', 'მ', 'm'],
  );

  /// Depth of a section. The unit isn't fixed yet: the methodology computes in
  /// centimetres, while the sample sheet writes soil horizons in metres.
  static const depth = MeasureSpec(kind: MeasureKind.range);

  /// Bulk density of soil. Table 1.11 runs from 0.3 to 1.7.
  static const soilBulkDensity = MeasureSpec(units: _gPerCm3, min: 0.1, max: 2.5);

  /// Density of rock. Table 1.12 runs from 1.5 to 2.8.
  static const rockDensity = MeasureSpec(units: _gPerCm3, min: 1, max: 3.5);

  /// Bulk density of wood.
  static const woodDensity = MeasureSpec(units: _tPerM3, min: 0.1, max: 1.5);

  /// Amount of a geomass, in tonnes per hectare.
  static const geomass = MeasureSpec(units: _tPerHa);

  /// A non-negative number whose unit isn't fixed yet.
  static const plain = MeasureSpec();
}
