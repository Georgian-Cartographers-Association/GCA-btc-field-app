import 'btk_record.dart';
import 'record_quality.dart';

/// Sections that can be reused. The basic section is what makes a record its
/// own (place, coordinates and date), so it is never copied.
const reusableSections = [
  FormSection.physGeo,
  FormSection.vegetation,
  FormSection.soil,
  FormSection.geomass,
  FormSection.vertStruct,
];

/// Copies [sections] of [source] into the empty parts of [target], and returns
/// how many fields and tables were filled. Anything already typed stays, and a
/// table is only filled when all its rows are blank.
int fillEmptyParts(BtkRecord target, BtkRecord source, Set<FormSection> sections) {
  var filled = 0;

  String text(String mine, String theirs) {
    if (mine.trim().isNotEmpty || theirs.trim().isEmpty) return mine;
    filled++;
    return theirs;
  }

  List<T> rows<T>(List<T> mine, List<T> theirs, Map<String, dynamic> Function(T) toJson,
      T Function(Map<String, dynamic>) fromJson) {
    final theirsUsed = theirs.where((r) => !isBlankRow(toJson(r)));
    if (theirsUsed.isEmpty || !mine.every((r) => isBlankRow(toJson(r)))) return mine;
    filled++;
    return theirsUsed.map((r) => fromJson(toJson(r))).toList();
  }

  if (sections.contains(FormSection.physGeo)) {
    target
      ..geologicalFormation = text(target.geologicalFormation, source.geologicalFormation)
      ..reliefType = text(target.reliefType, source.reliefType)
      ..morphologicalDesc = text(target.morphologicalDesc, source.morphologicalDesc)
      ..geomorphProcesses = text(target.geomorphProcesses, source.geomorphProcesses)
      ..migrationRegime = text(target.migrationRegime, source.migrationRegime)
      ..moistureDegree = text(target.moistureDegree, source.moistureDegree);
  }
  if (sections.contains(FormSection.vegetation)) {
    target.vegetation = rows(target.vegetation, source.vegetation, (r) => r.toJson(),
        VegetationRow.fromJson);
  }
  if (sections.contains(FormSection.soil)) {
    target
      ..soilTypeName = text(target.soilTypeName, source.soilTypeName)
      ..soilProfileDesc = text(target.soilProfileDesc, source.soilProfileDesc)
      ..geohorizonIndex = text(target.geohorizonIndex, source.geohorizonIndex)
      ..soilSurfaceFormation = text(target.soilSurfaceFormation, source.soilSurfaceFormation)
      ..soilHorizons = rows(target.soilHorizons, source.soilHorizons, (r) => r.toJson(),
          SoilHorizonRow.fromJson);
  }
  if (sections.contains(FormSection.geomass)) {
    final ownRows = target.geomasses;
    target.geomasses =
        rows(ownRows, source.geomasses, (r) => r.toJson(), GeomassRow.fromJson);
    // The unit says what the depths mean, so it only travels with them.
    if (!identical(target.geomasses, ownRows)) target.depthUnit = source.depthUnit;
    target
      ..experimentPlotSize = text(target.experimentPlotSize, source.experimentPlotSize)
      ..treePhytomass = rows(target.treePhytomass, source.treePhytomass, (r) => r.toJson(),
          TreePhytomassRow.fromJson);
  }
  if (sections.contains(FormSection.vertStruct)) {
    target
      ..vertStructTypeName = text(target.vertStructTypeName, source.vertStructTypeName)
      ..vertStructIndex = text(target.vertStructIndex, source.vertStructIndex)
      ..vertStructHeight = text(target.vertStructHeight, source.vertStructHeight)
      ..vertStructDesc = text(target.vertStructDesc, source.vertStructDesc);
  }
  return filled;
}

/// Named, reusable parts of a record.
class RecordTemplate {
  final String id;
  final String name;
  final BtkRecord content;

  const RecordTemplate({required this.id, required this.name, required this.content});

  /// Keeps only [sections] of [from], so no place or date goes into a template.
  factory RecordTemplate.fromRecord({
    required String id,
    required String name,
    required BtkRecord from,
    required Set<FormSection> sections,
  }) {
    final content = BtkRecord(id: id, date: DateTime.fromMillisecondsSinceEpoch(0));
    fillEmptyParts(content, from, sections);
    return RecordTemplate(id: id, name: name, content: content);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'content': content.toJson()};

  factory RecordTemplate.fromJson(Map<String, dynamic> j) => RecordTemplate(
        id: j['id'] as String,
        name: j['name'] as String,
        content: BtkRecord.fromJson(Map<String, dynamic>.from(j['content'] as Map)),
      );
}
