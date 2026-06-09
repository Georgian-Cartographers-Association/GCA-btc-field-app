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
        tier: j['tier'] ?? '',
        height: j['height'] ?? '',
        density: j['density'] ?? '',
        phenophase: j['phenophase'] ?? '',
        species: j['species'] ?? '',
      );
}

class SoilHorizonRow {
  String horizon;
  String description;

  SoilHorizonRow({this.horizon = '', this.description = ''});

  Map<String, dynamic> toJson() => {'horizon': horizon, 'description': description};
  factory SoilHorizonRow.fromJson(Map<String, dynamic> j) =>
      SoilHorizonRow(horizon: j['horizon'] ?? '', description: j['description'] ?? '');
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
        section: j['section'] ?? '',
        depth: j['depth'] ?? '',
        pedomassBulk: j['pedomassBulk'] ?? '',
        pedomassQty: j['pedomassQty'] ?? '',
        lithomassQty: j['lithomassQty'] ?? '',
        lithomassDensity: j['lithomassDensity'] ?? '',
        hydromassQty: j['hydromassQty'] ?? '',
        hydromassWet: j['hydromassWet'] ?? '',
        hydromassDry: j['hydromassDry'] ?? '',
        phytomassWet: j['phytomassWet'] ?? '',
        phytomassDry: j['phytomassDry'] ?? '',
      );
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
        species: j['species'] ?? '',
        bulkDensity: j['bulkDensity'] ?? '',
        wetWood: j['wetWood'] ?? '',
        wetLeaves: j['wetLeaves'] ?? '',
        wetBranches: j['wetBranches'] ?? '',
        wetRoots: j['wetRoots'] ?? '',
        wetTotal: j['wetTotal'] ?? '',
        dryWood: j['dryWood'] ?? '',
        dryLeaves: j['dryLeaves'] ?? '',
        dryBranches: j['dryBranches'] ?? '',
        dryRoots: j['dryRoots'] ?? '',
        dryTotal: j['dryTotal'] ?? '',
      );
}

class BtkRecord {
  final String id;
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

  factory BtkRecord.fromJson(Map<String, dynamic> j) => BtkRecord(
        id: j['id'] ?? '',
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        altitude: (j['altitude'] as num?)?.toDouble(),
        aspect: (j['aspect'] as num?)?.toDouble(),
        location: j['location'] ?? '',
        geologicalFormation: j['geologicalFormation'] ?? '',
        reliefType: j['reliefType'] ?? '',
        morphologicalDesc: j['morphologicalDesc'] ?? '',
        geomorphProcesses: j['geomorphProcesses'] ?? '',
        migrationRegime: j['migrationRegime'] ?? '',
        moistureDegree: j['moistureDegree'] ?? '',
        vegetation: (j['vegetation'] as List<dynamic>?)
                ?.map((e) => VegetationRow.fromJson(e))
                .toList() ??
            [VegetationRow()],
        soilTypeName: j['soilTypeName'] ?? '',
        soilProfileDesc: j['soilProfileDesc'] ?? '',
        soilHorizons: (j['soilHorizons'] as List<dynamic>?)
                ?.map((e) => SoilHorizonRow.fromJson(e))
                .toList() ??
            [SoilHorizonRow()],
        geohorizonIndex: j['geohorizonIndex'] ?? '',
        soilSurfaceFormation: j['soilSurfaceFormation'] ?? '',
        geomasses: (j['geomasses'] as List<dynamic>?)
                ?.map((e) => GeomassRow.fromJson(e))
                .toList() ??
            [GeomassRow()],
        experimentPlotSize: j['experimentPlotSize'] ?? '',
        treePhytomass: (j['treePhytomass'] as List<dynamic>?)
                ?.map((e) => TreePhytomassRow.fromJson(e))
                .toList() ??
            [TreePhytomassRow()],
        vertStructTypeName: j['vertStructTypeName'] ?? '',
        vertStructIndex: j['vertStructIndex'] ?? '',
        vertStructHeight: j['vertStructHeight'] ?? '',
        vertStructDesc: j['vertStructDesc'] ?? '',
        updatedAt: j['updatedAt'] != null
            ? DateTime.tryParse(j['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

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
