import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts, Printing;
import 'package:share_plus/share_plus.dart';
import '../models/btk_record.dart';
import '../models/gps_track.dart';

class ExportService {
  // ─── CSV ─────────────────────────────────────────────────────────────────────

  static String buildCsv(List<BtkRecord> records) {
    final buf = StringBuffer();
    // Header
    buf.writeln(
      'ID,თარიღი,განედი,გრძედი,ადგილმდებარეობა,'
      'გეოლ.ფ.,რელიეფი,მორფ.დახ.,გეომ.პრ.,მიგ.რეჟ.,დატ.ხ.,'
      'ნიადაგ.ტიპი,გეოჰ.ინდ.,ნ.ზ.ფ.ტ.,'
      'ვ.ს.ტიპ.,ვ.ს.ინდ.,ვ.ს.სიმ.',
    );
    for (final r in records) {
      buf.writeln([
        _q(r.id),
        _q(r.date.toString().split(' ')[0]),
        r.latitude?.toStringAsFixed(6) ?? '',
        r.longitude?.toStringAsFixed(6) ?? '',
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

  static Future<void> shareCsv(List<BtkRecord> records) async {
    final csv = buildCsv(records);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final file = XFile.fromData(bytes, name: 'btk_records.csv', mimeType: 'text/csv');
    await Share.shareXFiles([file], subject: 'ბტკ ჩანაწერები — CSV');
  }

  // ─── PDF ─────────────────────────────────────────────────────────────────────

  static Future<Uint8List> buildPdf(List<BtkRecord> records) async {
    // Try to load Georgian font; fall back to Helvetica if offline
    pw.Font? geoFont;
    try {
      geoFont = await PdfGoogleFonts.notoSansGeorgianRegular();
    } catch (_) {
      geoFont = null; // offline fallback
    }

    pw.TextStyle style(
            {double size = 10, bool bold = false, pw.Font? font}) =>
        pw.TextStyle(
          font: font ?? geoFont,
          fontSize: size,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        );

    final doc = pw.Document();

    for (final r in records) {
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
              _pdfRow('კოორდ.', '${r.latitude!.toStringAsFixed(6)}, ${r.longitude!.toStringAsFixed(6)}', style),
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
                    .map((v) => [v.tier, v.height, v.density, v.phenophase, v.species])
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
                data: r.soilHorizons.map((h) => [h.horizon, h.description]).toList(),
                columnWidths: {0: const pw.FixedColumnWidth(60), 1: const pw.FlexColumnWidth()},
                headerStyle: style(bold: true, size: 9),
                cellStyle: style(size: 9),
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              ),
            _pdfRow('გეოჰ. ინდ.', r.geohorizonIndex, style),
            _pdfRow('ნ.ზ.ფ. ტ.', r.soilSurfaceFormation, style),
            _pdfSep,
            // Vertical structure
            _pdfHeader('ბტკ-ის ვერტიკალური სტრუქტურა', style),
            _pdfRow('ტიპი', r.vertStructTypeName, style),
            _pdfRow('ინდ.', r.vertStructIndex, style),
            _pdfRow('სიმ.', r.vertStructHeight, style),
            _pdfRow('აღწ.', r.vertStructDesc, style),
          ],
        ),
      );
    }

    return doc.save();
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

    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: 'btk_records.pdf');
    } else {
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/btk_records.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ბტკ ჩანაწერები — PDF',
      );
    }
  }
}
