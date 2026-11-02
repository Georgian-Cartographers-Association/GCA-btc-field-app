import 'measure.dart';

// Stored data may come from old versions or edited files, so reading never
// fails on an unexpected type.
String _str(dynamic v) => v == null ? '' : v.toString();

double? _num(dynamic v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

List<T>? _rows<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) =>
    v is List
        ? v
            .whereType<Map>()
            .map((e) => fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : null;

class VegetationRow {
  String tier;
  String height;
  String density;
  String phenophase;
  String species;

  VegetationRow({
    this.tier = '',
    this.height = '',
    this.density = '',
    this.phenophase = '',
    this.species = '',
  });

  Map<String, dynamic> toJson() => {
        'tier': tier,
        'height': height,
        'density': density,
        'phenophase': phenophase,
        'species': species,
      };

  factory VegetationRow.fromJson(Map<String, dynamic> j) => VegetationRow(
        tier: _str(j['tier']),
        height: _str(j['height']),
        density: _str(j['density']),
        phenophase: _str(j['phenophase']),
        species: _str(j['species']),
      );

  double? get heightValue => Measures.vegHeight.value(height);
}

class SoilHorizonRow {
  String horizon;
  String description;

  SoilHorizonRow({this.horizon = '', this.description = ''});

  Map<String, dynamic> toJson() => {'horizon': horizon, 'description': description};
  factory SoilHorizonRow.fromJson(Map<String, dynamic> j) =>
      SoilHorizonRow(horizon: _str(j['horizon']), description: _str(j['description']));
}

class GeomassRow {
  String section;
  String depth;
  String pedomassBulk;
  String pedomassQty;
  String lithomassQty;
  String lithomassDensity;
  String hydromassQty;
  String hydromassWet;
  String hydromassDry;
  String phytomassWet;
  String phytomassDry;

  GeomassRow({
    this.section = '',
    this.depth = '',
    this.pedomassBulk = '',
    this.pedomassQty = '',
    this.lithomassQty = '',
    this.lithomassDensity = '',
    this.hydromassQty = '',
    this.hydromassWet = '',
    this.hydromassDry = '',
    this.phytomassWet = '',
    this.phytomassDry = '',
  });

  Map<String, dynamic> toJson() => {
        'section': section,
        'depth': depth,
        'pedomassBulk': pedomassBulk,
        'pedomassQty': pedomassQty,
        'lithomassQty': lithomassQty,
        'lithomassDensity': lithomassDensity,
        'hydromassQty': hydromassQty,
        'hydromassWet': hydromassWet,
        'hydromassDry': hydromassDry,
        'phytomassWet': phytomassWet,
        'phytomassDry': phytomassDry,
      };

  factory GeomassRow.fromJson(Map<String, dynamic> j) => GeomassRow(
        section: _str(j['section']),
        depth: _str(j['depth']),
        pedomassBulk: _str(j['pedomassBulk']),
        pedomassQty: _str(j['pedomassQty']),
        lithomassQty: _str(j['lithomassQty']),
        lithomassDensity: _str(j['lithomassDensity']),
        hydromassQty: _str(j['hydromassQty']),
        hydromassWet: _str(j['hydromassWet']),
        hydromassDry: _str(j['hydromassDry']),
        phytomassWet: _str(j['phytomassWet']),
        phytomassDry: _str(j['phytomassDry']),
      );

  MeasureRange? get depthRange => Measures.depth.range(depth);
  double? get pedomassBulkValue => Measures.soilBulkDensity.value(pedomassBulk);
  double? get pedomassQtyValue => Measures.geomass.value(pedomassQty);
  double? get lithomassQtyValue => Measures.geomass.value(lithomassQty);
  double? get lithomassDensityValue => Measures.rockDensity.value(lithomassDensity);
  double? get hydromassQtyValue => Measures.geomass.value(hydromassQty);
  double? get hydromassWetValue => Measures.plain.value(hydromassWet);
  double? get hydromassDryValue => Measures.plain.value(hydromassDry);
  double? get phytomassWetValue => Measures.geomass.value(phytomassWet);
  double? get phytomassDryValue => Measures.geomass.value(phytomassDry);
}

class TreePhytomassRow {
  String species;
  String bulkDensity;
  String wetWood;
  String wetLeaves;
  String wetBranches;
  String wetRoots;
  String wetTotal;
  String dryWood;
  String dryLeaves;
  String dryBranches;
  String dryRoots;
  String dryTotal;

  TreePhytomassRow({
    this.species = '',
    this.bulkDensity = '',
    this.wetWood = '',
    this.wetLeaves = '',
    this.wetBranches = '',
    this.wetRoots = '',
    this.wetTotal = '',
    this.dryWood = '',
    this.dryLeaves = '',
    this.dryBranches = '',
    this.dryRoots = '',
    this.dryTotal = '',
  });

  Map<String, dynamic> toJson() => {
        'species': species,
        'bulkDensity': bulkDensity,
        'wetWood': wetWood,
        'wetLeaves': wetLeaves,
        'wetBranches': wetBranches,
        'wetRoots': wetRoots,
        'wetTotal': wetTotal,
        'dryWood': dryWood,
        'dryLeaves': dryLeaves,
        'dryBranches': dryBranches,
        'dryRoots': dryRoots,
        'dryTotal': dryTotal,
      };

  factory TreePhytomassRow.fromJson(Map<String, dynamic> j) => TreePhytomassRow(
        species: _str(j['species']),
        bulkDensity: _str(j['bulkDensity']),
        wetWood: _str(j['wetWood']),
        wetLeaves: _str(j['wetLeaves']),
        wetBranches: _str(j['wetBranches']),
        wetRoots: _str(j['wetRoots']),
        wetTotal: _str(j['wetTotal']),
        dryWood: _str(j['dryWood']),
        dryLeaves: _str(j['dryLeaves']),
        dryBranches: _str(j['dryBranches']),
        dryRoots: _str(j['dryRoots']),
        dryTotal: _str(j['dryTotal']),
      );

  double? get bulkDensityValue => Measures.woodDensity.value(bulkDensity);
  double? get wetWoodValue => Measures.geomass.value(wetWood);
  double? get wetLeavesValue => Measures.geomass.value(wetLeaves);
  double? get wetBranchesValue => Measures.geomass.value(wetBranches);
  double? get wetRootsValue => Measures.geomass.value(wetRoots);
  double? get wetTotalValue => Measures.geomass.value(wetTotal);
  double? get dryWoodValue => Measures.geomass.value(dryWood);
  double? get dryLeavesValue => Measures.geomass.value(dryLeaves);
  double? get dryBranchesValue => Measures.geomass.value(dryBranches);
  double? get dryRootsValue => Measures.geomass.value(dryRoots);
  double? get dryTotalValue => Measures.geomass.value(dryTotal);
}

class BtkRecord {
  final String id;
  String name;
  DateTime date;
  double? latitude;
  double? longitude;
  double? altitude;  // metres above sea level
  double? aspect;    // compass bearing 0–360°
  String location;

  // Physical-geographic
  String geologicalFormation;
  String reliefType;
  String morphologicalDesc;
  String geomorphProcesses;
  String migrationRegime;
  String moistureDegree;

  // Vegetation
  List<VegetationRow> vegetation;

  // Soil
  String soilTypeName;
  String soilProfileDesc;
  List<SoilHorizonRow> soilHorizons;
  String geohorizonIndex;
  String soilSurfaceFormation;

  // Geomasses
  List<GeomassRow> geomasses;

  // Tree phytomass
  String experimentPlotSize;
  List<TreePhytomassRow> treePhytomass;

  // Vertical structure
  String vertStructTypeName;
  String vertStructIndex;
  String vertStructHeight;
  String vertStructDesc;

  // Sync metadata
  DateTime updatedAt;

  BtkRecord({
    required this.id,
    required this.date,
    this.name = '',
    this.latitude,
    this.longitude,
    this.altitude,
    this.aspect,
    this.location = '',
    this.geologicalFormation = '',
    this.reliefType = '',
    this.morphologicalDesc = '',
    this.geomorphProcesses = '',
    this.migrationRegime = '',
    this.moistureDegree = '',
    List<VegetationRow>? vegetation,
    this.soilTypeName = '',
    this.soilProfileDesc = '',
    List<SoilHorizonRow>? soilHorizons,
    this.geohorizonIndex = '',
    this.soilSurfaceFormation = '',
    List<GeomassRow>? geomasses,
    this.experimentPlotSize = '',
    List<TreePhytomassRow>? treePhytomass,
    this.vertStructTypeName = '',
    this.vertStructIndex = '',
    this.vertStructHeight = '',
    this.vertStructDesc = '',
    DateTime? updatedAt,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        vegetation = vegetation ?? [VegetationRow()],
        soilHorizons = soilHorizons ?? [SoilHorizonRow()],
        geomasses = geomasses ?? [GeomassRow()],
        treePhytomass = treePhytomass ?? [TreePhytomassRow()];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'aspect': aspect,
        'location': location,
        'geologicalFormation': geologicalFormation,
        'reliefType': reliefType,
        'morphologicalDesc': morphologicalDesc,
        'geomorphProcesses': geomorphProcesses,
        'migrationRegime': migrationRegime,
        'moistureDegree': moistureDegree,
        'vegetation': vegetation.map((v) => v.toJson()).toList(),
        'soilTypeName': soilTypeName,
        'soilProfileDesc': soilProfileDesc,
        'soilHorizons': soilHorizons.map((h) => h.toJson()).toList(),
        'geohorizonIndex': geohorizonIndex,
        'soilSurfaceFormation': soilSurfaceFormation,
        'geomasses': geomasses.map((g) => g.toJson()).toList(),
        'experimentPlotSize': experimentPlotSize,
        'treePhytomass': treePhytomass.map((t) => t.toJson()).toList(),
        'vertStructTypeName': vertStructTypeName,
        'vertStructIndex': vertStructIndex,
        'vertStructHeight': vertStructHeight,
        'vertStructDesc': vertStructDesc,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BtkRecord.fromJson(Map<String, dynamic> j) {
    final date = DateTime.tryParse(_str(j['date'])) ?? DateTime.now();
    return BtkRecord(
      id: _str(j['id']),
      name: _str(j['name']),
      date: date,
      latitude: _num(j['latitude']),
      longitude: _num(j['longitude']),
      altitude: _num(j['altitude']),
      aspect: _num(j['aspect']),
      location: _str(j['location']),
      geologicalFormation: _str(j['geologicalFormation']),
      reliefType: _str(j['reliefType']),
      morphologicalDesc: _str(j['morphologicalDesc']),
      geomorphProcesses: _str(j['geomorphProcesses']),
      migrationRegime: _str(j['migrationRegime']),
      moistureDegree: _str(j['moistureDegree']),
      vegetation: _rows(j['vegetation'], VegetationRow.fromJson),
      soilTypeName: _str(j['soilTypeName']),
      soilProfileDesc: _str(j['soilProfileDesc']),
      soilHorizons: _rows(j['soilHorizons'], SoilHorizonRow.fromJson),
      geohorizonIndex: _str(j['geohorizonIndex']),
      soilSurfaceFormation: _str(j['soilSurfaceFormation']),
      geomasses: _rows(j['geomasses'], GeomassRow.fromJson),
      experimentPlotSize: _str(j['experimentPlotSize']),
      treePhytomass: _rows(j['treePhytomass'], TreePhytomassRow.fromJson),
      vertStructTypeName: _str(j['vertStructTypeName']),
      vertStructIndex: _str(j['vertStructIndex']),
      vertStructHeight: _str(j['vertStructHeight']),
      vertStructDesc: _str(j['vertStructDesc']),
      // Without a timestamp, the record's own date is the safest age: "now"
      // would let an old record look newer than everything else.
      updatedAt: DateTime.tryParse(_str(j['updatedAt'])) ?? date,
    );
  }

  /// Reads a record kept under [storedId], which fills in a missing `id`.
  factory BtkRecord.fromStored(String storedId, Map<String, dynamic> j) =>
      BtkRecord.fromJson(_str(j['id']).isEmpty ? {...j, 'id': storedId} : j);

  MeasureRange? get vertHeightRange => Measures.vertHeight.range(vertStructHeight);
  double? get plotArea => Measures.plotSize.area(experimentPlotSize);

  String toEmailText({bool georgian = true}) {
    final buf = StringBuffer();
    buf.writeln('ბუნებრივ-ტერიტორიული კომპლექსის (ბტკ) აღწერა');
    buf.writeln('ID: $id');
    buf.writeln('თარიღი: ${date.toString().split(' ')[0]}');
    if (latitude != null) buf.writeln('კოორდინატები: $latitude, $longitude');
    buf.writeln('ადგილმდებარეობა: $location');
    buf.writeln('---');
    buf.writeln('გეოლ. ფორმაცია: $geologicalFormation');
    buf.writeln('რელიეფის ტიპი: $reliefType');
    buf.writeln('მორფ. დახ.: $morphologicalDesc');
    buf.writeln('გეომ. პროც.: $geomorphProcesses');
    buf.writeln('მიგ. რეჟიმი: $migrationRegime');
    buf.writeln('დატენ. ხ.: $moistureDegree');
    buf.writeln('---');
    buf.writeln('ნიადაგი: $soilTypeName');
    buf.writeln('ნ. პროფ.: $soilProfileDesc');
    buf.writeln('ვ.ს. ტიპი: $vertStructTypeName  ინდ: $vertStructIndex  სიმ: $vertStructHeight');
    return buf.toString();
  }
}
