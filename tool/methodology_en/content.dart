// Text of the English field guide. Original wording, written for the app.
// Keep to characters the standard PDF fonts can print (Windows-1252):
// no Georgian letters, no >= or similar symbols.

sealed class Block {
  const Block();
}

class Chapter extends Block {
  const Chapter(this.title);
  final String title;
}

class Section extends Block {
  const Section(this.title);
  final String title;
}

class Sub extends Block {
  const Sub(this.title);
  final String title;
}

class Para extends Block {
  const Para(this.text);
  final String text;
}

class Bullets extends Block {
  const Bullets(this.items);
  final List<String> items;
}

class Table extends Block {
  const Table(this.header, this.rows, {this.widths});
  final List<String> header;
  final List<List<String>> rows;
  final List<double>? widths;
}

class Note extends Block {
  const Note(this.text);
  final String text;
}

const guideTitle = 'BTC Field Guide';
const guideShortTitle = 'BTC Field Guide';
const guideSubtitle =
    'Describing a natural-territorial complex in the field: a short English '
    'companion to the BTC Field App';
const guideEdition = 'English edition 1.0 (draft), 2026';

const coverNote =
    'This guide is an independent, abridged text written for the English '
    'interface of the BTC Field App. It is not a translation. It follows the '
    'landscape-geophysical field method of Prof. Niko Beruchashvili as taught '
    'at Ivane Javakhishvili Tbilisi State University, and explains how to fill '
    'in each part of the app\'s form. The full method, with its theory, '
    'examples and tables, is in the Georgian methodology manual (TSU, '
    'Tbilisi, 2024), which is the reference wherever the two differ.';

const guide = <Block>[
  // 1 ------------------------------------------------------------------------
  Chapter('1. Before you start'),
  Section('1.1 What you are describing'),
  Para(
    'A natural-territorial complex (BTC, from its Georgian name) is a piece '
    'of land where relief, rock, water, air, soil, plants and animals work '
    'together as one system. In the field the smallest such unit, the '
    'facies, is the usual object: a patch with one position on the slope, '
    'one kind of substrate, one moisture regime and one plant community.',
  ),
  Para(
    'The method looks at a BTC as a vertical column. It runs from the top '
    'of the vegetation down through the soil to the rock below, and is made '
    'of layers called geohorizons. Each geohorizon is built from geomasses: '
    'air, living plant matter, dead plant matter, soil, rock and water. '
    'Describing a BTC means recording where it is, what conditions shape '
    'it, and how this column is built.',
  ),
  Section('1.2 The three stages of the work'),
  Bullets([
    'Before the field: collect topographic maps at a large scale, geological '
        'and soil maps, satellite images and earlier studies of the area. '
        'Decide how detailed the survey has to be.',
    'In the field: choose the plots, describe them on the form, take samples '
        'and photographs.',
    'After the field: process samples, compute masses, compare the plots '
        'and draw conclusions or maps.',
  ]),
  Para(
    'The app supports the field stage. Records can be exported as PDF, '
    'Excel, CSV, KML or BTC files for the desk work that follows.',
  ),
  Section('1.3 Choosing the plots'),
  Para(
    'Nobody can observe a whole landscape, so the work is done on a few '
    'well chosen plots. The largest is the key plot. Every smaller plot of '
    'the same record lies inside it.',
  ),
  Bullets([
    'Key plot: placed in the most typical BTC, so that what you learn can be '
        'carried over to a wider area. Add more key plots where the vertical '
        'structure or the state of the BTC clearly changes. In a forest, make '
        'it large enough to hold about 50 trees. Lay it out as a rectangle '
        'with the long side running down the slope, and measure all four '
        'sides with a tape.',
    'Sample area: used to measure the mass of trees and shrubs. Its size '
        'depends on the landscape and on how detailed the survey is (see the '
        'table below).',
    'Record plot: a small square or rectangle (1 × 1 m, 0.5 × 0.5 m, 1 × 0.5 m '
        'or 2 × 1 m) for cutting and weighing grasses and dead plant matter. '
        'Usually 3 to 5 per BTC, or a single one in a very simple BTC.',
    'Soil pit: usually 1 m long, 0.5 m wide and 1 m deep. Rock or many '
        'stones may stop it at about 0.5 m.',
  ]),
  Table(
    ['Landscape', 'Detail', 'Size (m)', 'Area (m²)'],
    [
      ['Complex, sparse or park forests', 'high', '100 × 100', '10 000'],
      ['', 'medium', '100 × 50', '5 000'],
      ['', 'low', '50 × 20', '1 000'],
      ['Medium and low forests', 'high', '100 × 50', '5 000'],
      ['', 'medium', '50 × 20', '1 000'],
      ['', 'low', '25 × 10', '250'],
      ['Semi-arid and semi-humid, with shrubs', 'high', '10 × 5', '50'],
      ['', 'medium', '5 × 2', '10'],
      ['', 'low', '2.5 × 2', '5'],
      ['Semi-desert and desert', 'high', '10 × 5', '50'],
      ['', 'medium', '5 × 2', '10'],
      ['', 'low', '1 × 1', '1'],
    ],
    widths: [3.2, 1.2, 1.6, 1.4],
  ),
  Para(
    'A key plot may sit on the border of two neighbouring facies only if '
    'both have the same type of vertical structure.',
  ),
  Section('1.4 Naming the record'),
  Para(
    'Give each key plot a short code: an abbreviation of the study area '
    'and a number, for example BAK 1. When several teams work in the same '
    'area, let the hundreds show the team: BAK 101, 102, 103 for the first '
    'team, BAK 201, 202 for the second. Use the code as the record name in '
    'the app, and the Group field to keep one expedition or route together.',
  ),
  Section('1.5 Using the app in the field'),
  Bullets([
    'Fill language: on the Basic tab choose Georgian, English or both. With '
        'both, each text field gets a second, English box, and the PDF prints '
        'the two versions together.',
    'Voice typing: the app uses the keyboard\'s own microphone. Gboard on '
        'Android recognises Georgian and English. Settings > Tips explains '
        'other devices.',
    'Offline: everything is saved on the device first, and synchronised '
        'later if you use Cloud or Expedition storage.',
    'Photos: each tab has its own photo panel. Photograph the plot, the soil '
        'profile and the vertical structure.',
  ]),

  // 2 ------------------------------------------------------------------------
  Chapter('2. Basic tab'),
  Section('2.1 Date, name and group'),
  Para(
    'The date is filled in when the record is created. Change it if you '
    'enter notes later. The name is the plot code (section 1.4).',
  ),
  Section('2.2 Location'),
  Para(
    'Describe the place in words so that someone else can find it again '
    'without GPS. Tie it to at least two permanent landmarks, such as a '
    'village, a bridge, a road junction or a survey point, and give the '
    'smallest administrative unit. A position relative to another plot is '
    'useful only as an addition.',
  ),
  Para(
    'If the plot lies in the Caucasus, name its landscape after '
    'N. Beruchashvili\'s Landscape Map of the Caucasus (1:1 000 000, 1979) '
    'and note the number of the landscape on that map. Using one map for '
    'every plot keeps the records comparable.',
  ),
  Section('2.3 Coordinates, altitude and aspect'),
  Bullets([
    'Coordinates: press Detect via GPS and wait for a good accuracy, or type '
        'them in. The converter accepts decimal degrees, degrees and minutes, '
        'degrees-minutes-seconds and UTM.',
    'Altitude: height above sea level in metres. Phone GPS height can be '
        'tens of metres off, so check it against a topographic map.',
    'Aspect: the direction the slope faces, in degrees from north '
        '(0 = north, 90 = east, 180 = south, 270 = west). Leave it empty on '
        'flat ground.',
  ]),
  Table(
    ['Class', 'Aspect', 'Degrees'],
    [
      ['1', 'North', '337.5 - 22.5'],
      ['2', 'North-east', '22.5 - 67.5'],
      ['3', 'East', '67.5 - 112.5'],
      ['4', 'South-east', '112.5 - 157.5'],
      ['5', 'South', '157.5 - 202.5'],
      ['6', 'South-west', '202.5 - 247.5'],
      ['7', 'West', '247.5 - 292.5'],
      ['8', 'North-west', '292.5 - 337.5'],
    ],
    widths: [1, 2, 2],
  ),
  Para(
    'If you recorded a GPS track for the route, link it to the record so '
    'that the plot can be placed on the path later.',
  ),

  // 3 ------------------------------------------------------------------------
  Chapter('3. Physico-geographic tab'),
  Section('3.1 Geological formation'),
  Para(
    'Name the rock the BTC is built on, its age if known, and how it lies. '
    'The best evidence is a natural outcrop or a cut such as a road '
    'cutting or a stream bank. Without one, use a geological map; for '
    'Georgia the 1:200 000 sheets are the easiest to obtain. Plants can '
    'help: some grow only on limestone, others only on sand.',
  ),
  Para(
    'Write, for example: "Middle Jurassic porphyrite series, weathered at '
    'the surface" or "Quaternary alluvium: pebbles and sand".',
  ),
  Section('3.2 Relief type'),
  Para(
    'Look at the group of landforms around the plot, not at a single form, '
    'and name the type by the process that made it. Common types are:',
  ),
  Bullets([
    'denudational, erosion-denudational, erosional',
    'erosion-accumulative, accumulative, accumulative-erosional',
    'karst, arid-denudational',
    'gravitational, structural (petrogenic)',
    'glacial and old glacial (paleoglacial)',
  ]),
  Para(
    'The relief type says a lot about how stable the landscape is under '
    'human use, which is why it is recorded separately from the shape.',
  ),
  Section('3.3 Morphological description'),
  Para(
    'Describe the shape and size of the landform and the plot\'s place on '
    'it: crest, upper, middle or lower slope, foot, terrace, floodplain. '
    'Give length and width where they matter, how densely and how deeply '
    'the surface is cut by gullies, and the height difference between the '
    'lowest and highest point of the plot. State the slope steepness.',
  ),
  Table(
    ['Slope (degrees)', 'Description'],
    [
      ['0 - 4', 'flat or almost flat'],
      ['4 - 10', 'gentle'],
      ['10 - 20', 'slightly steep slope'],
      ['20 - 30', 'moderately steep slope'],
      ['30 - 45', 'steep slope'],
      ['45 - 60', 'very steep slope'],
      ['60 - 90', 'cliff, rock face'],
    ],
    widths: [1.4, 3],
  ),
  Section('3.4 Modern geomorphological processes'),
  Para(
    'List the processes active now, and say how strong they are and how '
    'much of the plot they affect. The most frequent are:',
  ),
  Bullets([
    'weathering debris (scree), rockfall, landslides',
    'mudflows and debris flows, snow avalanches',
    'gully erosion and sheet erosion',
    'nivation, karst and clastokarst',
    'creep, solifluction and other slow slope movement',
    'deflation (wind erosion)',
  ]),
  Section('3.5 Migration regime'),
  Para(
    'The migration regime describes how water and the matter it carries '
    'move through the BTC. It depends on the position in the relief and on '
    'the slope.',
  ),
  Bullets([
    'Eluvial (autonomous): flat or almost flat watersheds. Water comes only '
        'from precipitation; matter is leached downwards and out.',
    'Transeluvial: slopes. Matter both arrives from above and leaves '
        'downslope, so the BTC is a place of transit.',
    'Eluvial-accumulative and accumulative-eluvial: lower slopes and foot '
        'slopes, where matter starts to accumulate.',
    'Transaccumulative: hollows and valley floors with throughflow.',
    'Superaquatic: groundwater is close to the surface and reaches the '
        'soil.',
    'Subaquatic: under water, at the bottom of lakes and rivers.',
  ]),
  Para(
    'When the vertical structure index is written (section 7.4), the '
    'regime and slope together give a number at its start:',
  ),
  Table(
    ['No.', 'Regime and slope'],
    [
      ['1', 'autonomous, 0 - 4°'],
      ['2', 'autonomous, 4 - 10°'],
      ['3', 'transeluvial, 10 - 20°'],
      ['4', 'transeluvial, 20 - 30°'],
      ['5', 'transeluvial, 30 - 45°'],
      ['6', 'transeluvial, over 45°'],
      ['7', 'badlands'],
      ['8', 'cliffs'],
      ['9', 'eluvial-accumulative, 10 - 20°'],
      ['10', 'eluvial-accumulative, 4 - 10°'],
      ['11', 'eluvial-accumulative, 0 - 4°'],
      ['12', 'superaquatic, 0 - 4°'],
      ['13', 'superaquatic, 4 - 10°'],
      ['14', 'transaccumulative'],
      ['15', 'accumulative-eluvial'],
    ],
    widths: [0.6, 3],
  ),
  Para(
    'Do not apply the slope classes mechanically. On the upper and middle '
    'slope the transeluvial regime should prevail, on the lower slope the '
    'accumulative one. Look also at the relief and regime of the landscape '
    'above the plot.',
  ),
  Section('3.6 Moisture degree'),
  Para(
    'Record where the moisture comes from and how much there is. Most '
    'places have more than one source, and the source can change with the '
    'state of the BTC during the year.',
  ),
  Bullets([
    'Atmospheric: moisture from precipitation only.',
    'Ground: from groundwater, with or without springs on the plot.',
    'Deluvial: from water running down the surface of the slope.',
    'Floodplain: from floods.',
  ]),
  Table(
    ['Degree', 'Soil', 'Typical state'],
    [
      ['insufficient', 'very dry', 'arid'],
      ['weak', 'partly moist', 'semi-arid'],
      ['optimal', 'moist', 'humid'],
      ['abundant', 'very moist', 'humid'],
      ['excessive', 'wet', 'extra-humid'],
    ],
    widths: [1.4, 1.4, 1.4],
  ),
  Para(
    'Note the groundwater level if you can find it, from the water in a '
    'well or from the depth at which water seeps into the soil pit. '
    'Willow, alder, reeds and sedges also point to shallow groundwater.',
  ),

  // 4 ------------------------------------------------------------------------
  Chapter('4. Vegetation tab'),
  Section('4.1 What to record'),
  Para(
    'Work inside the key plot. First list every species you find. If you '
    'cannot name a plant, give it a temporary name or number and take a '
    'specimen for the herbarium, so that it can be identified later.',
  ),
  Para(
    'Enter one row per tier and species group. Each row has a tier, a '
    'height, a density, a phenophase and the species.',
  ),
  Section('4.2 Tier'),
  Para(
    'Each tier is a fixed height band, so the classes are the same in '
    'every landscape and records can be compared.',
  ),
  Table(
    ['Tier', 'Height', 'Tier', 'Height'],
    [
      ['I', '0 - 5 cm', 'VI', '2 - 4 m'],
      ['II', '5 - 25 cm', 'VII', '4 - 8 m'],
      ['III', '25 - 50 cm', 'VIII', '8 - 16 m'],
      ['IV', '50 - 100 cm', 'IX', '16 - 32 m'],
      ['V', '1 - 2 m', 'X', 'over 32 m'],
    ],
  ),
  Note(
    'The tiers in this table grow with height: tier I is the lowest '
    'layer. Check the convention used by your course before you start, and '
    'use the same one for every record of the survey.',
  ),
  Section('4.3 Height'),
  Para(
    'Give the average height of the species or layer in metres. Measure '
    'grasses together with their flowers and seed heads. Trees can be '
    'measured with a clinometer or estimated against a pole of known '
    'length.',
  ),
  Section('4.4 Density'),
  Para(
    'Density is the share of the ground that the plants cover when seen '
    'from above (projective cover). Use one of two scales and say which.',
  ),
  Table(
    ['Drude', 'Meaning'],
    [
      ['sol.', 'very rare, almost no cover'],
      ['+', 'rare, small cover'],
      ['1', 'plentiful with very little cover, or rare with large cover'],
      ['2', 'quite plentiful, cover under 1/20 of the area'],
      ['3', 'cover 1/4 to 1/2 of the area'],
      ['4', 'cover 1/2 to 3/4 of the area'],
      ['5', 'cover over 3/4 of the area'],
    ],
    widths: [0.8, 4],
  ),
  Para(
    'The ten-point scale gives one point for each 10 % of cover: '
    '10 points is 90 - 100 %, 5 points is 40 - 50 %, 1 point is under '
    '10 %. Note also whether the plants grow evenly, in clumps or in '
    'patches.',
  ),
  Section('4.5 Phenophase'),
  Table(
    ['Code', 'Phase', 'Code', 'Phase'],
    [
      ['1', 'vegetative growth', '5', 'seed ripening and shedding'],
      ['2', 'budding', '6', 'flowers and leaves falling'],
      ['3', 'flowering', '7', 'drying, dying back'],
      ['4', 'fruiting', '8', 'dormancy'],
    ],
    widths: [0.6, 2, 0.6, 2.4],
  ),
  Section('4.6 Naming the community'),
  Para(
    'Name a plant association after the dominant species of its main '
    'tier, with the most important species, the dominant or edificator, '
    'last: a hornbeam-oak forest is an oak forest with hornbeam. A plant '
    'formation is named after the dominants of all tiers, for example '
    '"hornbeam-oak forest with deciduous shrubs".',
  ),
  Para(
    'In forests also note the regrowth: how many young trees there are, '
    'which species, and whether they are spread evenly. Uneven regrowth '
    'needs an explanation, such as grazing or a gap in the canopy.',
  ),

  // 5 ------------------------------------------------------------------------
  Chapter('5. Soil tab'),
  Section('5.1 The soil pit'),
  Para(
    'Dig the pit where the soil is typical for the plot, with the face to '
    'be described in good light. Fix a measuring tape to the face with '
    'zero at the surface, mark the horizon boundaries with a knife, and '
    'describe each horizon from the top down.',
  ),
  Section('5.2 Soil type name'),
  Para(
    'Give the type, subtype and variety, for example "brown forest soil, '
    'leached, medium loam, shallow". Note any sign of human change: '
    'ploughing, terracing, compaction, erosion.',
  ),
  Section('5.3 Genetic horizons'),
  Para(
    'Add one row per horizon. Write its symbol and depth, for example '
    'A1 0-12 for an A1 horizon from the surface to 12 cm. The usual '
    'symbols are:',
  ),
  Bullets([
    'A0: litter, dead plant material on the surface.',
    'A1: dark humus-accumulative horizon.',
    'A2: pale eluvial horizon, leached of humus and clay.',
    'Ap: ploughed layer.',
    'A/B or A3: transition from A to B.',
    'B: illuvial horizon, usually denser and browner, where substances from '
        'above accumulate. B1, B2, B3 by decreasing humus colour; Bk with '
        'accumulated carbonates.',
    'G: gley horizon, grey or bluish-green, formed under constant '
        'waterlogging, often with rusty spots.',
    'C: parent material not changed by soil formation.',
    'D: underlying rock of a different kind below the parent material.',
  ]),
  Para(
    'Small letters after the symbol add detail: g signs of gleying, t clay '
    'accumulation, h illuvial humus, k or ca carbonates, cs gypsum, sa other '
    'soluble salts, sn concretions, m a cemented layer.',
  ),
  Section('5.4 Horizon description'),
  Para(
    'The app\'s legend lists the properties in a fixed order. Describe '
    'each that you can see:',
  ),
  Bullets([
    'Colour: darker means more humus; brown and red tones come from iron '
        'and manganese; whitish tones from leaching or carbonates.',
    'Texture (mechanical composition): clay, heavy, medium or light loam, '
        'sandy loam, sand. Judge it by rolling moist soil between the '
        'fingers.',
    'Structure: the shape of the aggregates: crumb, granular, nutty, '
        'blocky, prismatic, platy, or structureless.',
    'Porosity: fine, medium or coarse pores; cracks.',
    'Density: loose, slightly compact, compact, very compact (how hard it '
        'is to push in a knife).',
    'New formations: carbonate spots and veins, iron and manganese '
        'concretions, rust mottles, salt crystals.',
    'Gravel % and roots %: share of stones and of roots in the horizon.',
    'Moisture: dry, slightly moist, moist, wet.',
    'Humus type: mull, moder or mor.',
    'Lower boundary: sharp (transition 2 - 3 cm), clear (3 - 5 cm) or '
        'gradual (over 5 cm); also its shape: even, wavy, tongued.',
  ]),
  Section('5.5 Geohorizon index and surface formation'),
  Para(
    'For each soil horizon write the geohorizon it belongs to (chapter 7). '
    'Under soil surface formation describe what covers the soil: litter, '
    'moss, stones, crust, bare ground.',
  ),

  // 6 ------------------------------------------------------------------------
  Chapter('6. Geomass tab'),
  Section('6.1 Geomasses'),
  Para(
    'A geomass is a body of matter of one kind inside the BTC. Its '
    'class is written with a capital letter, and smaller letters add the '
    'type. The main classes are:',
  ),
  Table(
    ['Index', 'Geomass', 'Examples'],
    [
      ['A', 'aeromass', 'air between and above the plants'],
      [
        'P',
        'phytomass',
        'living plants: Pt trunks and branches, Pf leaves, '
            'Ps roots',
      ],
      [
        'M',
        'mortmass',
        'dead plant matter: standing dead grass, litter, '
            'fallen wood',
      ],
      [
        'S',
        'pedomass',
        'fine soil, by texture: Sa clay, Ss loam, Sc sandy '
            'loam, Sp sand',
      ],
      ['L', 'lithomass', 'stones and rock: Ls silicate, Lk carbonate'],
      [
        'H',
        'hydromass',
        'water: H\' too little, H\'\' optimal, H\'\'\' too '
            'much',
      ],
    ],
    widths: [0.7, 1.3, 4],
  ),
  Para(
    'The Georgian manual gives the full list of types, for example leaves '
    'of mesophytes, xerophytes and evergreens, or needles and grass stems.',
  ),
  Section('6.2 Units'),
  Para(
    'Masses are given per area, usually in tonnes per hectare (t/ha) or '
    'grams per square metre (1 t/ha = 100 g/m²). Bulk density and density '
    'are given in g/cm³.',
  ),
  Section('6.3 The geomass table'),
  Para('Enter one row per layer of the soil pit, with its depth in cm.'),
  Bullets([
    'Pedomass: bulk density (g/cm³) and quantity (t/ha). Quantity = bulk '
        'density × layer thickness (cm) × share of fine soil in the layer (as a '
        'fraction) × 100. Example: 1.0 g/cm³, 100 cm, 50 % gives 5 000 t/ha.',
    'Lithomass: density of the rock (g/cm³) and quantity (t/ha), computed '
        'the same way with the share of stones.',
    'Hydromass: soil moisture wet and dry, and the quantity of water. '
        'Quantity = pedomass of the layer × moisture (%) / 100.',
    'Phytomass: wet and dry mass of roots in the layer.',
  ]),
  Para(
    'Add the layers to get the total for the profile. In mountains the '
    'soil is rarely deeper than 1 m, so totals usually cover the top metre.',
  ),
  Sub('Typical rock densities (g/cm³)'),
  Table(
    ['Rock', 'Density', 'Rock', 'Density'],
    [
      ['granite, gneiss', '2.7', 'sandstone, clay', '2.3'],
      ['basalt', '2.8', 'conglomerate', '2.5'],
      ['porphyrite, andesite', '2.7', 'limestone', '2.5'],
      ['shale', '2.7', 'marl', '2.6'],
      ['heavy tuff', '2.4', 'weathered rock', '1.5 - 2.5'],
    ],
    widths: [2.2, 1, 2, 1.2],
  ),
  Sub('Soil moisture by weighing'),
  Para(
    'Take samples at fixed depths (for example 0-5, 5-10, 15-20, 25-30, '
    '35-40, 45-50 cm and deeper), seal each in a bag with a label giving '
    'the plot, date and depth, and weigh them in closed tins. Dry them at '
    '100 - 105 °C for 5 - 7 hours, weigh, dry for another hour and weigh '
    'again, until the weight stops changing. Pick out and weigh gravel '
    'over 3 mm. Then:',
  ),
  Para(
    'moisture (%) = 100 × (wet weight - dry weight) / (dry weight - tin - '
    'gravel), where the wet and dry weights include the tin.',
  ),
  Section('6.4 Tree phytomass'),
  Para(
    'In the sample area count the trees, measure the diameter at breast '
    'height and the height of each, and find the stem volume from volume '
    'tables. Enter the plot size, and for each species the volume and the '
    'wet and dry mass of wood, leaves, branches and roots in t/ha. The app '
    'adds the totals.',
  ),

  // 7 ------------------------------------------------------------------------
  Chapter('7. Vertical structure tab'),
  Section('7.1 The sketch'),
  Para(
    'Start with a coloured drawing of the BTC column, from the tree tops '
    'to the rock. Give each geomass its own colour, for example brown for '
    'trunks and branches, dark green for needles and light green for leaves '
    'and grass. In forests use two scales: one for the whole column and a '
    'larger one for the thin layers near the ground. Attach a photo of the '
    'sketch on this tab.',
  ),
  Section('7.2 Separating geohorizons'),
  Para(
    'Go down the column. A new geohorizon starts where a geomass appears '
    'or disappears, where the ratio between geomasses changes clearly, or '
    'where their shape and arrangement change, for example where the crown '
    'gives way to bare trunks. Separate geohorizons of the same rank '
    'throughout the profile. Record for each one which soil horizon or '
    'plant tier it corresponds to.',
  ),
  Section('7.3 Geohorizon index'),
  Bullets([
    'Order: write the geomass classes from the heaviest to the lightest, '
        'with no comma between classes. AP is a layer of air with plants; '
        'PA is a layer where plants weigh more than the air.',
    'Cover: after each geomass give its cover in % (plants, air) or its '
        'share of the volume (soil, stones). Air and water get no number.',
    'Limits: end the index with the upper and lower limits in metres.',
    'Leave out minor parts: include a geomass only if it is over 1 % of the '
        'weight or over 5 % of the cover or volume, and mention the rest in '
        'the description.',
    'Repeat nothing: a property shared by several geohorizons is written '
        'only once, in the highest one.',
  ]),
  Para(
    'Some rules of thumb: forest crowns are mostly air (A first), the '
    'trunk zone below them mostly plant (P first). Under grass the class '
    'changes when plant cover reaches 70 - 90 %. Stones are two to three '
    'times denser than soil, so they come first when they fill over 30 % '
    'of a layer. Trunks and branches outweigh leaves even when they cover '
    'less, so Pt is written before Pf.',
  ),
  Section('7.4 Vertical structure type'),
  Para(
    'The class of the structure is named after the geomass that shapes '
    'it: phytogenic (living plants), postphytogenic (dead plant matter), '
    'hydrogenic (snow, frozen ground, standing water, ice), pedogenic (bare '
    'soil, such as a harvested field) or lithogenic (rock, beach). '
    'Transitional classes are common. The type is then written as a '
    'capital letter:',
  ),
  Table(
    ['Code', 'Type'],
    [
      ['K', 'Colchic humid forests and shrubs'],
      [
        'F',
        'humid mesophytic broadleaf forests (beech, lime, hornbeam, maple, '
            'elm)',
      ],
      ['SA', 'semi-arid mesophytic forests (oak, oriental hornbeam)'],
      ['T', 'humid dark coniferous forests (spruce, fir)'],
      ['Q', 'semi-arid light coniferous forests (pine)'],
      ['H', 'extra-humid hydrophytic forests (alder, willow, poplar)'],
      ['TF', 'humid mixed broadleaf and dark coniferous forests'],
      ['P', 'xerophytic open woodland (arid open forests, juniper)'],
      ['L', 'humid high-mountain grassland (alpine and subalpine meadows)'],
      ['SH', 'semi-humid and semi-arid grassland (meadow steppe, steppe)'],
      ['G', 'humid meadows of low and middle mountains'],
      ['A', 'arid deserts and semi-deserts'],
      ['C', 'cliffs'],
    ],
    widths: [0.6, 4],
  ),
  Para(
    'Marshes, glaciers, farmland and settlements have their own signs, '
    'which are given in the Georgian manual.',
  ),
  Section('7.5 Height, thickness and complexity'),
  Para(
    'Enter the total height of the structure in metres. Its thickness '
    'is the distance from the upper to the lower limit, without the air '
    'above and the rock below, and is graded on a doubling scale:',
  ),
  Table(
    ['Code', 'Thickness grade', 'Complexity', 'Geohorizons'],
    [
      ['0', 'nano, under 1 m', 'primitive', '2 - 3'],
      ['1', 'micro, 1 - 2 m', 'simple', '4 - 5'],
      ['2', 'meso, 2 - 4 m', 'medium', '6 - 7'],
      ['3', 'mesomacro, 4 - 8 m', 'complicated', '8 - 9'],
      ['4', 'macromeso, 8 - 16 m', 'complex', '10 - 11'],
      ['5', 'macro, 16 - 32 m', 'very complex', 'over 12'],
      ['6', 'mega, over 32 m', '', ''],
    ],
    widths: [0.7, 2.2, 1.5, 1.2],
  ),
  Para(
    'Intensity is the number of geohorizons per metre of profile: low '
    '(one per 2 m), medium (one per 1 - 2 m) or high (one per metre).',
  ),
  Section('7.6 Writing the full index'),
  Para(
    'The landscape unit index joins these parts: the migration regime '
    'number, the structure type, small letters for the substrate and '
    'additions, the thickness grade, and the landscape number from the map '
    'in brackets. For example 5Fk5w (71): a transeluvial slope of 30 - 45° '
    '(5), humid beech forest (F) on carbonate rock (k), structure 16 - 32 m '
    'thick (5), with evergreen Colchic shrubs (w), landscape 71.',
  ),
  Bullets([
    'Additions: n dead cover, i low grass, ii mixed herbs, iii tall herbs, '
        'w evergreen shrubs, v deciduous shrubs, x xerophytes, p ferns, '
        'g halophytes, m mosses and lichens, d young and secondary forest.',
    'Substrate: c crystalline, t terrigenous, k carbonate, s saline, a '
        'alluvial, p proluvial, g glacial, o colluvial deposits.',
  ]),
  Section('7.7 Description'),
  Para(
    'In the description field, explain how the part above ground relates '
    'to the part below: how deep the roots reach compared with the height of '
    'the plants, where water and litter collect, and how the layers depend '
    'on each other. Mention the geomasses left out of the indexes.',
  ),

  // 8 ------------------------------------------------------------------------
  Chapter('8. Glossary'),
  Bullets([
    'BTC: natural-territorial complex, the unit of landscape study.',
    'Facies: the smallest BTC, uniform in position, substrate, moisture and '
        'plant cover.',
    'Geomass: a body of matter of one kind (air, plants, dead plant matter, '
        'soil, rock, water) inside a BTC.',
    'Geohorizon: a layer of the BTC column with a uniform set and ratio of '
        'geomasses.',
    'Vertical structure: the order of geohorizons and the links between '
        'them.',
    'State (stex): the condition of a BTC over one day; a BTC passes through '
        'several states in a year.',
    'Key plot: the main plot where a BTC is described.',
    'Migration regime: how water and matter move into, through and out of a '
        'BTC.',
    'Projective cover: the share of the ground covered by plants, seen from '
        'above.',
    'Mortmass: dead plant matter, standing or lying.',
    'Edificator: the species that shapes the community and its environment.',
  ]),
  Section('Sources'),
  Para(
    'N. Beruchashvili. Methods of mapping the states of natural-territorial '
    'complexes and of landscape-geophysical research. Tbilisi, 1983 (in '
    'Russian).',
  ),
  Para(
    'Methodology of landscape field research and mapping, compiled for '
    'geography students of Ivane Javakhishvili Tbilisi State University, '
    'Tbilisi, 2024 (in Georgian; translated from the 1983 manual by '
    'D. Nikolaishvili, with additions from T. Gordeziani, 2014). This is the '
    'full Georgian methodology bundled with the app.',
  ),
  Para(
    'N. Beruchashvili. Landscape Map of the Caucasus, 1:1 000 000. '
    'Tbilisi, 1979.',
  ),
];
