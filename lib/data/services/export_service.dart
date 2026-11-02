import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show Printing;
import 'package:share_plus/share_plus.dart';
import '../../models/btk_record.dart';
import '../../models/photo.dart';
import '../../utils/coord_converter.dart';
import '../../features/settings/domain/settings_provider.dart';
import '../../models/gps_track.dart';
import '../../database/btk_database.dart';
import '../../l10n/generated/app_localizations.dart';

class ExportService {

  /// iPads show the share sheet as a popover, and refuse to open it with no
  /// position to attach to.
  static Future<void> _shareFiles(List<XFile> files, {String? subject}) async {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    await Share.shareXFiles(
      files,
      subject: subject,
      sharePositionOrigin:
          Rect.fromCenter(center: size.center(Offset.zero), width: 1, height: 1),
    );
  }

  // ─── CSV ─────────────────────────────────────────────────────────────────────

  static String buildCsv(List<BtkRecord> records,
      {ExportCoordFormat coordFormat = ExportCoordFormat.dd}) {
    final buf = StringBuffer();
    // Header
    buf.writeln(
      'ID,თარიღი,განედი,გრძედი,ადგილმდებარეობა,'
      'გეოლ.ფ.,რელიეფი,მორფ.დახ.,გეომ.პრ.,მიგ.რეჟ.,დატ.ხ.,'
      'ნიადაგ.ტიპი,გეოჰ.ინდ.,ნ.ზ.ფ.ტ.,'
      'ვ.ს.ტიპ.,ვ.ს.ინდ.,ვ.ს.სიმ.',
    );
    for (final r in records) {
      final (latStr, lonStr) = _fmtCoordPair(
          r.latitude, r.longitude, coordFormat);
      buf.writeln([
        _q(r.id),
        _q(r.date.toString().split(' ')[0]),
        latStr,
        lonStr,
        _q(r.location),
        _q(r.geologicalFormation),
        _q(r.reliefType),
        _q(r.morphologicalDesc),
        _q(r.geomorphProcesses),
        _q(r.migrationRegime),
        _q(r.moistureDegree),
        _q(r.soilTypeName),
        _q(r.geohorizonIndex),
        _q(r.soilSurfaceFormation),
        _q(r.vertStructTypeName),
        _q(r.vertStructIndex),
        _q(r.vertStructHeight),
      ].join(','));
    }
    return buf.toString();
  }

  static (String, String) _fmtCoordPair(
      double? lat, double? lon, ExportCoordFormat fmt) {
    if (lat == null || lon == null) return ('', '');
    return switch (fmt) {
      ExportCoordFormat.dd => (
          lat.toStringAsFixed(6),
          lon.toStringAsFixed(6)
        ),
      ExportCoordFormat.dm => (
          CoordConverter.ddToDm(lat, isLat: true),
          CoordConverter.ddToDm(lon, isLat: false)
        ),
      ExportCoordFormat.dms => (
          CoordConverter.ddToDms(lat, isLat: true),
          CoordConverter.ddToDms(lon, isLat: false)
        ),
      ExportCoordFormat.utm37 => _utmPair(lat, lon, zone: 37),
      ExportCoordFormat.utm38 => _utmPair(lat, lon, zone: 38),
    };
  }

  static (String, String) _utmPair(double lat, double lon,
      {int zone = 38}) {
    final utm = zone == 37
        ? CoordConverter.toUtm37N(lat, lon)
        : CoordConverter.toUtm38N(lat, lon);
    return (
      'N ${utm.northing.toStringAsFixed(1)}',
      'E ${utm.easting.toStringAsFixed(1)}'
    );
  }

  static String _q(String s) => '"${s.replaceAll('"', '""')}"';

  // ─── GeoJSON ──────────────────────────────────────────────────────────────────

  static String buildGeoJson(List<BtkRecord> records) {
    final features = records.map((r) {
      final hasCoords = r.latitude != null && r.longitude != null;
      return {
        'type': 'Feature',
        'geometry': hasCoords
            ? {
                'type': 'Point',
                'coordinates': [r.longitude, r.latitude],
              }
            : null,
        'properties': {
          'id': r.id,
          'date': r.date.toIso8601String().split('T').first,
          'location': r.location,
          'geological_formation': r.geologicalFormation,
          'relief_type': r.reliefType,
          'morphological_desc': r.morphologicalDesc,
          'geomorph_processes': r.geomorphProcesses,
          'migration_regime': r.migrationRegime,
          'moisture_degree': r.moistureDegree,
          'soil_type': r.soilTypeName,
          'geohorizon_index': r.geohorizonIndex,
          'soil_surface_formation': r.soilSurfaceFormation,
          'vert_struct_type': r.vertStructTypeName,
          'vert_struct_index': r.vertStructIndex,
          'vert_struct_height': r.vertStructHeight,
        },
      };
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'type': 'FeatureCollection',
      'name': 'BTK Field Records',
      'crs': {
        'type': 'name',
        'properties': {'name': 'urn:ogc:def:crs:OGC:1.3:CRS84'},
      },
      'features': features,
    });
  }

  static Future<void> shareGeoJson(
      List<BtkRecord> records, AppLocalizations l10n) async {
    final json = buildGeoJson(records);
    final bytes = Uint8List.fromList(utf8.encode(json));
    final file = XFile.fromData(bytes,
        name: 'btk_records.geojson',
        mimeType: 'application/geo+json');
    await _shareFiles([file], subject: l10n.shareRecordsGeoJson);
  }

  static Future<void> shareCsv(List<BtkRecord> records, AppLocalizations l10n,
      {ExportCoordFormat coordFormat = ExportCoordFormat.dd}) async {
    final csv = buildCsv(records, coordFormat: coordFormat);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final file = XFile.fromData(bytes, name: 'btk_records.csv', mimeType: 'text/csv');
    await _shareFiles([file], subject: l10n.shareRecordsCsv);
  }

  // ─── PDF ─────────────────────────────────────────────────────────────────────

  static Future<Uint8List> buildPdf(List<BtkRecord> records) async {
    // Bundled, so Georgian text prints without a network connection.
    final geoFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansGeorgian-Regular.ttf'));

    pw.TextStyle style(
            {double size = 10, bool bold = false, pw.Font? font}) =>
        pw.TextStyle(
          font: font ?? geoFont,
          fontSize: size,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        );

    // Pre-load photos for every record (Photos tab, soil, vert struct)
    final generalImgMap = <String, List<pw.MemoryImage>>{};
    final soilImgMap = <String, List<pw.MemoryImage>>{};
    final vertImgMap = <String, List<pw.MemoryImage>>{};
    for (final r in records) {
      generalImgMap[r.id] = await _loadPdfImages(r.id);
      soilImgMap[r.id] = await _loadPdfImages('${r.id}_soil');
      vertImgMap[r.id] = await _loadPdfImages('${r.id}_vertStruct');
    }

    final doc = pw.Document();

    for (final r in records) {
      final generalImgs = generalImgMap[r.id] ?? [];
      final soilImgs = soilImgMap[r.id] ?? [];
      final vertImgs = vertImgMap[r.id] ?? [];

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) => [
            // Title
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.green800,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'ბუნებრივ-ტერიტორიული კომპლექსის (ბტკ) აღწერა',
                style: style(size: 13, bold: true).copyWith(color: PdfColors.white),
              ),
            ),
            pw.SizedBox(height: 8),
            // Basic info
            _pdfRow('ID', r.id, style),
            _pdfRow('თარიღი', r.date.toString().split(' ')[0], style),
            if (r.latitude != null && r.longitude != null)
              _pdfRow('კოორდ.',
                  '${r.latitude!.toStringAsFixed(6)}, ${r.longitude!.toStringAsFixed(6)}',
                  style),
            _pdfRow('ადგილმდ.', r.location, style),
            _pdfSep,
            // Physical geo
            _pdfHeader('ფიზიკურ-გეოგრაფიული დახასიათება', style),
            _pdfRow('გეოლ. ფ.', r.geologicalFormation, style),
            _pdfRow('რელიეფი', r.reliefType, style),
            _pdfRow('მორფ. დახ.', r.morphologicalDesc, style),
            _pdfRow('გეომ. პრ.', r.geomorphProcesses, style),
            _pdfRow('მიგ. რეჟ.', r.migrationRegime, style),
            _pdfRow('დატ. ხ.', r.moistureDegree, style),
            _pdfSep,
            // Vegetation table
            if (r.vegetation.isNotEmpty) ...[
              _pdfHeader('მცენარეულობა', style),
              pw.TableHelper.fromTextArray(
                headers: ['იარ.', 'სიმ.', 'სიმძლ.', 'ფენოფ.', 'სახეობა'],
                data: r.vegetation
                    .map((v) =>
                        [v.tier, v.height, v.density, v.phenophase, v.species])
                    .toList(),
                headerStyle: style(bold: true, size: 9),
                cellStyle: style(size: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              ),
              _pdfSep,
            ],
            // Soil
            _pdfHeader('ნიადაგი', style),
            _pdfRow('ტიპი', r.soilTypeName, style),
            _pdfRow('პროფ. დახ.', r.soilProfileDesc, style),
            if (r.soilHorizons.isNotEmpty)
              pw.TableHelper.fromTextArray(
                headers: ['ჰ-ტი', 'დახასიათება'],
                data: r.soilHorizons
                    .map((h) => [h.horizon, h.description])
                    .toList(),
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),
                  1: const pw.FlexColumnWidth()
                },
                headerStyle: style(bold: true, size: 9),
                cellStyle: style(size: 9),
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              ),
            _pdfRow('გეოჰ. ინდ.', r.geohorizonIndex, style),
            _pdfRow('ნ.ზ.ფ. ტ.', r.soilSurfaceFormation, style),
            if (soilImgs.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              ..._pdfPhotoRows(soilImgs),
            ],
            _pdfSep,
            // Vertical structure
            _pdfHeader('ბტკ-ის ვერტიკალური სტრუქტურა', style),
            _pdfRow('ტიპი', r.vertStructTypeName, style),
            _pdfRow('ინდ.', r.vertStructIndex, style),
            _pdfRow('სიმ.', r.vertStructHeight, style),
            _pdfRow('აღწ.', r.vertStructDesc, style),
            if (vertImgs.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              ..._pdfPhotoRows(vertImgs),
            ],
            if (generalImgs.isNotEmpty) ...[
              _pdfSep,
              _pdfHeader('ფოტოები', style),
              ..._pdfPhotoRows(generalImgs),
            ],
          ],
        ),
      );
    }

    return doc.save();
  }

  static Future<List<pw.MemoryImage>> _loadPdfImages(String photoKey) async {
    final result = <pw.MemoryImage>[];
    try {
      final photos = await BtkDatabase.getPhotos(photoKey);
      for (final p in photos) {
        try {
          final bytes = await File(p.filePath).readAsBytes();
          result.add(pw.MemoryImage(bytes));
        } catch (_) {}
      }
    } catch (_) {}
    return result;
  }

  // Separate rows, so a long set of photos can continue on the next page.
  static List<pw.Widget> _pdfPhotoRows(List<pw.MemoryImage> images) {
    const maxPerRow = 3;
    const imgW = 158.0;
    const imgH = 118.0;
    final rows = <pw.Widget>[];
    for (int i = 0; i < images.length; i += maxPerRow) {
      final end = (i + maxPerRow) > images.length ? images.length : i + maxPerRow;
      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            children: images.sublist(i, end).map((img) => pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 4),
                  child: pw.ClipRRect(
                    horizontalRadius: 3,
                    verticalRadius: 3,
                    child: pw.Image(img,
                        width: imgW, height: imgH, fit: pw.BoxFit.cover),
                  ),
                )).toList(),
          ),
        ),
      );
    }
    return rows;
  }

  static pw.Widget _pdfRow(String label, String value,
          pw.TextStyle Function({double size, bool bold, pw.Font? font}) style) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 100,
              child: pw.Text('$label:', style: style(bold: true, size: 9)),
            ),
            pw.Expanded(child: pw.Text(value, style: style(size: 9))),
          ],
        ),
      );

  static pw.Widget _pdfHeader(String title,
          pw.TextStyle Function({double size, bool bold, pw.Font? font}) style) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4, bottom: 4),
        child: pw.Text(title, style: style(bold: true, size: 11)),
      );

  static final pw.Widget _pdfSep = pw.Divider(color: PdfColors.grey400, height: 12);

  // ─── GPX ─────────────────────────────────────────────────────────────────────

  static String buildGpx(GpsTrack track) {
    final dateStr = track.startedAt.toIso8601String().split('T').first;
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln(
        '<gpx version="1.1" creator="BTC Field App" '
        'xmlns="http://www.topografix.com/GPX/1/1">');
    buf.writeln('  <trk>');
    buf.writeln('    <name>GPS Track $dateStr</name>');
    buf.writeln('    <trkseg>');
    for (final p in track.points) {
      buf.writeln(
          '      <trkpt lat="${p.lat.toStringAsFixed(7)}" '
          'lon="${p.lon.toStringAsFixed(7)}">');
      buf.writeln('        <ele>${p.altitude.toStringAsFixed(1)}</ele>');
      buf.writeln('        <time>${p.time.toUtc().toIso8601String()}</time>');
      buf.writeln('      </trkpt>');
    }
    buf.writeln('    </trkseg>');
    buf.writeln('  </trk>');
    buf.writeln('</gpx>');
    return buf.toString();
  }

  static Future<void> shareGpx(GpsTrack track, AppLocalizations l10n) async {
    final gpx = buildGpx(track);
    final bytes = Uint8List.fromList(utf8.encode(gpx));
    final dateStr =
        track.startedAt.toIso8601String().split('T').first;
    final file = XFile.fromData(bytes,
        name: 'track_$dateStr.gpx',
        mimeType: 'application/gpx+xml');
    await _shareFiles([file], subject: l10n.shareGpsTrack(dateStr));
  }

  static Future<void> sharePdf(
      Uint8List bytes, String filename, AppLocalizations l10n) async {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } else {
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/$filename');
      await file.writeAsBytes(bytes);
      await _shareFiles(
        [XFile(file.path)],
        subject: l10n.shareBtkFile(filename),
      );
    }
  }

  static Future<void> savePdf(
      Uint8List bytes, String filename, BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return;
    }

    try {
      final isDesktop =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;

      // Desktop: file_picker returns path, we write manually.
      // Mobile: pass bytes so file_picker writes via SAF/document picker —
      // user sees system "Save to" dialog and picks Downloads, Drive, etc.
      final path = await FilePicker.platform.saveFile(
        dialogTitle: l10n.savePdfTitle,
        fileName: filename,
        type: isDesktop ? FileType.custom : FileType.any,
        allowedExtensions: isDesktop ? ['pdf'] : null,
        bytes: isDesktop ? null : bytes,
      );

      if (path == null) return; // user cancelled

      if (isDesktop) {
        await File(path).writeAsBytes(bytes);
      }

      if (context.mounted) {
        final msg = isDesktop ? l10n.savedAtPath(path) : l10n.pdfSaved;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  // ── Filename helpers ────────────────────────────────────────────────────────

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _safeName(String s) =>
      s.replaceAll(RegExp(r'[/\\:*?"<>|]'), '').trim();

  static String _label(BtkRecord r) => r.name.isNotEmpty
      ? _safeName(r.name)
      : r.id.substring(0, r.id.length < 8 ? r.id.length : 8);

  static String pdfFilename(List<BtkRecord> records) {
    if (records.length == 1) {
      final r = records.first;
      return 'btk_${_label(r)}_${_fmtDate(r.date)}.pdf';
    }
    return 'btk_${records.length}_records_${_fmtDate(DateTime.now())}.pdf';
  }

  static String _btkFilename(List<BtkRecord> records) {
    if (records.length == 1) {
      final r = records.first;
      return 'btk_${_label(r)}_${_fmtDate(r.date)}.btk';
    }
    return 'btk_export_${_fmtDate(DateTime.now())}.btk';
  }

  // ── BTK import/export ────────────────────────────────────────────────────────

  static Future<void> exportBtk(
      List<BtkRecord> records, BuildContext context) async {
        final l10n = AppLocalizations.of(context)!;
    final payload = jsonEncode({
      'btk_export_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'records': records.map((r) => r.toJson()).toList(),
    });
    final bytes = utf8.encode(payload);
    final filename = _btkFilename(records);

    if (kIsWeb) {
      final file = XFile.fromData(
        Uint8List.fromList(bytes),
        name: filename,
        mimeType: 'application/json',
      );
      await _shareFiles([file], subject: filename);
      return;
    }

    try {
      final isDesktop =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;
      final path = await FilePicker.platform.saveFile(
        dialogTitle: l10n.exportBtkTitle,
        fileName: filename,
        type: isDesktop ? FileType.custom : FileType.any,
        allowedExtensions: isDesktop ? ['btk'] : null,
        bytes: isDesktop ? null : Uint8List.fromList(bytes),
      );
      if (path == null) return;
      if (isDesktop) await File(path).writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isDesktop ? l10n.savedAtPath(path) : l10n.exported),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorWithDetail('$e'))));
      }
    }
  }

  /// Picks a .btk file and parses it. Returns null if user cancels.
  static Future<List<BtkRecord>?> parseBtkFile(AppLocalizations l10n) async {
    // Android doesn't support custom MIME-less extensions via FileType.custom
    final isDesktop = !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final result = await FilePicker.platform.pickFiles(
      type: isDesktop ? FileType.custom : FileType.any,
      allowedExtensions: isDesktop ? ['btk', 'json'] : null,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final f = result.files.first;
    final String content;
    if (f.bytes != null) {
      content = utf8.decode(f.bytes!);
    } else if (f.path != null) {
      content = await File(f.path!).readAsString();
    } else {
      throw Exception(l10n.fileReadFailed);
    }

    final map = jsonDecode(content) as Map<String, dynamic>;
    if (map['btk_export_version'] == null || map['records'] == null) {
      throw Exception(l10n.invalidBtkFile);
    }
    final list = map['records'] as List<dynamic>;
    return list
        .map((r) => BtkRecord.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ── KML ──────────────────────────────────────────────────────────────────────

  static String buildKml(List<BtkRecord> records) {
    final sb = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2">')
      ..writeln('<Document>')
      ..writeln('  <name><![CDATA[ბტკ ჩანაწერები]]></name>');

    for (final r in records) {
      if (r.latitude == null || r.longitude == null) continue;
      final title = r.name.isNotEmpty ? r.name : 'ბტკ #${r.id}';
      final desc = [
        'ID: ${r.id}',
        'თარიღი: ${_fmtDate(r.date)}',
        if (r.location.isNotEmpty) 'ლოკაცია: ${r.location}',
        if (r.geologicalFormation.isNotEmpty) 'გეოლ. ფორმაცია: ${r.geologicalFormation}',
        if (r.reliefType.isNotEmpty) 'რელიეფი: ${r.reliefType}',
        if (r.soilTypeName.isNotEmpty) 'ნიადაგი: ${r.soilTypeName}',
        if (r.moistureDegree.isNotEmpty) 'ტენიანობა: ${r.moistureDegree}',
      ].join('\n');
      final alt = r.altitude ?? 0.0;
      sb
        ..writeln('  <Placemark>')
        ..writeln('    <name><![CDATA[$title]]></name>')
        ..writeln('    <description><![CDATA[$desc]]></description>')
        ..writeln('    <Point>')
        ..writeln('      <coordinates>${r.longitude},'
            '${r.latitude},$alt</coordinates>')
        ..writeln('    </Point>')
        ..writeln('  </Placemark>');
    }

    sb.writeln('</Document>');
    sb.writeln('</kml>');
    return sb.toString();
  }

  static Future<void> shareKml(
      List<BtkRecord> records, AppLocalizations l10n) async {
    final content = buildKml(records);
    final bytes = utf8.encode(content);
    final filename = 'btk_${_fmtDate(DateTime.now())}.kml';

    if (kIsWeb) {
      final file = XFile.fromData(bytes, name: filename,
          mimeType: 'application/vnd.google-earth.kml+xml');
      await _shareFiles([file], subject: filename);
      return;
    }
    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/$filename');
    await file.writeAsBytes(bytes);
    await _shareFiles([XFile(file.path)], subject: l10n.shareRecordsKml);
  }

  // ── .btkz (ZIP with photos) ──────────────────────────────────────────────────

  static Future<void> exportBtkz(
      List<BtkRecord> records, BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final built = await buildBtkz(records);
    final zipBytes = built.bytes;
    final photoCount = built.photoCount;
    final trackCount = built.trackCount;
    final filename = records.length == 1
        ? 'btk_${_label(records.first)}_${_fmtDate(records.first.date)}.btkz'
        : 'btk_export_${_fmtDate(DateTime.now())}.btkz';

    if (kIsWeb) {
      await _shareFiles(
          [XFile.fromData(zipBytes, name: filename)],
          subject: filename);
      return;
    }

    try {
      final isDesktop =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;
      final path = await FilePicker.platform.saveFile(
        dialogTitle: l10n.exportBtkzTitle,
        fileName: filename,
        type: isDesktop ? FileType.custom : FileType.any,
        allowedExtensions: isDesktop ? ['btkz'] : null,
        bytes: isDesktop ? null : zipBytes,
      );
      if (path == null) return;
      if (isDesktop) await File(path).writeAsBytes(zipBytes);
      if (context.mounted) {
        final suffix = [
          if (photoCount > 0) l10n.photosCount(photoCount),
          if (trackCount > 0) l10n.tracksCount(trackCount),
        ].join(', ');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isDesktop
              ? l10n.savedAtPath(path)
              : suffix.isNotEmpty
                  ? l10n.exportedWith(suffix)
                  : l10n.exported),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorWithDetail('$e'))));
      }
    }
  }

  @visibleForTesting
  static Future<({Uint8List bytes, int photoCount, int trackCount})> buildBtkz(
      List<BtkRecord> records) async {
    final archive = Archive();

    // records.json
    final recordsJson = jsonEncode({
      'btk_export_version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'records': records.map((r) => r.toJson()).toList(),
    });
    final rBytes = utf8.encode(recordsJson);
    archive.addFile(ArchiveFile('records.json', rBytes.length, rBytes));

    // photos
    final List<Map<String, dynamic>> photosMeta = [];
    if (!kIsWeb) {
      for (final r in records) {
        final photos = await BtkDatabase.getRecordPhotos(r.id);
        for (final p in photos) {
          final f = File(p.filePath);
          if (!await f.exists()) continue;
          final ext = p.filePath.split('.').last.toLowerCase();
          final arcName = 'photos/${p.id}.$ext';
          final pBytes = await f.readAsBytes();
          archive.addFile(ArchiveFile(arcName, pBytes.length, pBytes));
          photosMeta.add({...p.toMap(), 'archive_path': arcName});
        }
      }
    }

    final pJson = utf8.encode(jsonEncode(photosMeta));
    archive.addFile(ArchiveFile('photos.json', pJson.length, pJson));

    // GPS tracks that overlap with record dates
    final List<Map<String, dynamic>> tracksMeta = [];
    if (!kIsWeb) {
      final recordDays = records
          .map((r) => DateUtils.dateOnly(r.date))
          .toSet();
      final allTracks = await BtkDatabase.getAllTracks();
      for (final t in allTracks) {
        if (!recordDays.contains(DateUtils.dateOnly(t.startedAt))) continue;
        if (t.points.isEmpty) continue;
        final gpxBytes = utf8.encode(buildGpx(t));
        final arcName = 'tracks/${t.id}.gpx';
        archive.addFile(ArchiveFile(arcName, gpxBytes.length, gpxBytes));
        tracksMeta.add({...t.toMap(), 'archive_path': arcName});
      }
    }
    final tJson = utf8.encode(jsonEncode(tracksMeta));
    archive.addFile(ArchiveFile('tracks.json', tJson.length, tJson));

    return (
      bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
      photoCount: photosMeta.length,
      trackCount: tracksMeta.length,
    );
  }

  /// Returns null if user cancels.
  static Future<({List<BtkRecord> records, int photoCount, int trackCount})?> parseBtkzFile(
      AppLocalizations l10n) async {
    final isDesktop = !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final result = await FilePicker.platform.pickFiles(
      type: isDesktop ? FileType.custom : FileType.any,
      allowedExtensions: isDesktop ? ['btkz'] : null,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final f = result.files.first;
    final List<int> bytes;
    if (f.bytes != null) {
      bytes = f.bytes!;
    } else if (f.path != null) {
      bytes = await File(f.path!).readAsBytes();
    } else {
      throw Exception(l10n.fileReadFailed);
    }

    return readBtkz(bytes, l10n);
  }

  @visibleForTesting
  static Future<({List<BtkRecord> records, int photoCount, int trackCount})>
      readBtkz(List<int> bytes, AppLocalizations l10n) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    final rFile = archive.findFile('records.json');
    if (rFile == null) throw Exception(l10n.invalidBtkzFile);
    final map = jsonDecode(utf8.decode(rFile.content as List<int>))
        as Map<String, dynamic>;
    final records = (map['records'] as List)
        .map((r) => BtkRecord.fromJson(r as Map<String, dynamic>))
        .toList();

    int photoCount = 0;
    final pFile = archive.findFile('photos.json');
    if (pFile != null && !kIsWeb) {
      final meta = jsonDecode(utf8.decode(pFile.content as List<int>)) as List;
      final dir = Platform.isAndroid
          ? (await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory())
          : await getApplicationDocumentsDirectory();
      for (final m in meta) {
        final arcPath = m['archive_path'] as String;
        final photoFile = archive.findFile(arcPath);
        if (photoFile == null) continue;
        final localPath = '${dir.path}/${arcPath.split('/').last}';
        await File(localPath).writeAsBytes(photoFile.content as List<int>);
        await BtkDatabase.insertPhoto(Photo(
          id: m['id'] as String,
          recordId: m['record_id'] as String,
          filePath: localPath,
          caption: m['caption'] as String? ?? '',
          sortOrder: m['sort_order'] as int? ?? 0,
          createdAt: DateTime.parse(m['created_at'] as String),
        ));
        photoCount++;
      }
    }

    // Restore GPS tracks
    int trackCount = 0;
    final tFile = archive.findFile('tracks.json');
    if (tFile != null && !kIsWeb) {
      final meta = jsonDecode(utf8.decode(tFile.content as List<int>)) as List;
      for (final m in meta) {
        try {
          final t = GpsTrack.fromMap({
            'id': m['id'] as String,
            'started_at': m['started_at'] as String,
            'ended_at': m['ended_at'],
            'points_json': m['points_json'] as String,
          });
          await BtkDatabase.insertTrack(t);
          trackCount++;
        } catch (_) {}
      }
    }

    return (records: records, photoCount: photoCount, trackCount: trackCount);
  }
}
