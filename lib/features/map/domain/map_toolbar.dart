const mapButtonSize = 44.0;
const mapButtonGap = 8.0;

/// How many buttons a column of [height] can hold.
int mapButtonsThatFit(double height) =>
    ((height + mapButtonGap) / (mapButtonSize + mapButtonGap)).floor();

/// Splits [tools] between the column and the tools menu. Everything stays in
/// the column when it fits. Otherwise one place goes to the menu button and the
/// lowest [rank]s fill the rest. Both lists keep the order of [tools].
({List<T> shown, List<T> hidden}) splitMapTools<T>(
  List<T> tools, {
  required double height,
  required int Function(T) rank,
}) {
  final fit = mapButtonsThatFit(height);
  if (tools.length <= fit) return (shown: tools, hidden: <T>[]);
  final keep = (List.of(tools)..sort((a, b) => rank(a).compareTo(rank(b))))
      .take(fit < 1 ? 0 : fit - 1)
      .toSet();
  return (
    shown: tools.where(keep.contains).toList(),
    hidden: tools.where((t) => !keep.contains(t)).toList(),
  );
}
