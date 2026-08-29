import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts, Printing;
import 'package:share_plus/share_plus.dart';
import '../../models/btk_record.dart';
import '../../utils/coord_converter.dart';
import '../../features/settings/domain/settings_provider.dart';
import '../../models/gps_track.dart';
import '../../database/btk_database.dart';

class ExportService {
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

  static Future<void> shareGeoJson(List<BtkRecord> records) async {
    final json = buildGeoJson(records);
    final bytes = Uint8List.fromList(utf8.encode(json));
    final file = XFile.fromData(bytes,
        name: 'btk_records.geojson',
        mimeType: 'application/geo+json');
    await Share.shareXFiles([file], subject: 'ბტკ ჩანაწერები — GeoJSON');
  }

  static Future<void> shareCsv(List<BtkRecord> records,
      {ExportCoordFormat coordFormat = ExportCoordFormat.dd}) async {
    final csv = buildCsv(records, coordFormat: coordFormat);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final file = XFile.fromData(bytes, name: 'btk_records.csv', mimeType: 'text/csv');
    await Share.shareXFiles([file], subject: 'ბტკ ჩანაწერები — CSV');
  }

  // ─── PDF ─────────────────────────────────────────────────────────────────────

  static Future<Uint8List> buildPdf(List<BtkRecord> records) async {
    pw.Font? geoFont;
    try {
      geoFont = await PdfGoogleFonts.notoSansGeorgianRegular();
    } catch (_) {}

    pw.TextStyle style(
            {double size = 10, bool bold = false, pw.Font? font}) =>
        pw.TextStyle(
          font: font ?? geoFont,
          fontSize: size,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        );

    // Pre-load section photos for every record (soil + vert struct)
    final soilImgMap = <String, List<pw.MemoryImage>>{};
    final vertImgMap = <String, List<pw.MemoryImage>>{};
    for (final r in records) {
      soilImgMap[r.id] = await _loadPdfImages('${r.id}_soil');
      vertImgMap[r.id] = await _loadPdfImages('${r.id}_vertStruct');
    }

    final doc = pw.Document();

    for (final r in records) {
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
            if (r.latitude != null)
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
              _pdfPhotoGrid(soilImgs),
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
              _pdfPhotoGrid(vertImgs),
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

  static pw.Widget _pdfPhotoGrid(List<pw.MemoryImage> images) {
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
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, children: rows);
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

  static Future<void> shareGpx(GpsTrack track) async {
    final gpx = buildGpx(track);
    final bytes = Uint8List.fromList(utf8.encode(gpx));
    final dateStr =
        track.startedAt.toIso8601String().split('T').first;
    final file = XFile.fromData(bytes,
        name: 'track_$dateStr.gpx',
        mimeType: 'application/gpx+xml');
    await Share.shareXFiles([file], subject: 'GPS ტრეკი — $dateStr');
  }

  static Future<void> sharePdf(List<BtkRecord> records) async {
    final bytes = await buildPdf(records);
    final filename = _pdfFilename(records);

    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } else {
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/$filename');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ბტკ — $filename',
      );
    }
  }

  static Future<void> savePdf(
      List<BtkRecord> records, BuildContext context) async {
    final bytes = await buildPdf(records);
    final filename = _pdfFilename(records);

    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return;
    }

    try {
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'PDF შენახვა',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (path == null) return;
        await File(path).writeAsBytes(bytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('შენახულია: $path'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        final dir = Platform.isIOS
            ? await getApplicationDocumentsDirectory()
            : await getExternalStorageDirectory();
        if (dir == null) throw Exception('შენახვის საქაღალდე ვერ მოიძებნა');
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('შენახულია:\n${file.path}'),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('შეცდომა: $e')),
        );
      }
    }
  }

  static String _pdfFilename(List<BtkRecord> records) {
    String fmtDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    String safeName(String s) => s.replaceAll(RegExp(r'[/\\:*?"<>|]'), '').trim();

    if (records.length == 1) {
      final r = records.first;
      final label = r.name.isNotEmpty ? safeName(r.name) : r.id.substring(0, 8);
      return 'btk_${label}_${fmtDate(r.date)}.pdf';
    }

    return 'btk_${records.length}_records_${fmtDate(DateTime.now())}.pdf';
  }
}
