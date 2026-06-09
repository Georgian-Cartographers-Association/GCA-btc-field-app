extension DurationX on Duration {
  /// Formats duration as Georgian string: "2 სთ 15 წთ", "5 წთ 30 წმ", "45 წმ"
  String toGeorgianString() {
    final h = inHours;
    final m = inMinutes.remainder(60);
    final s = inSeconds.remainder(60);
    if (h > 0) return '$h სთ $m წთ';
    if (m > 0) return '$m წთ $s წმ';
    return '$s წმ';
  }
}
