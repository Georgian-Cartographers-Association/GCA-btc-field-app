import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// One worksheet. A [num] cell is stored as a number and anything else as text,
/// so a text cell is never run as a formula. Null leaves the cell empty.
class XlsxSheet {
  final String name;
  final List<Object?> header;
  final List<List<Object?>> rows;

  const XlsxSheet(this.name, this.header, this.rows);
}

const _contentTypeHead =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
    '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>';

const _rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
    '</Relationships>';

// Style 1 is the bold used for header rows.
const _styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
    '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
    '<fills count="2"><fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill></fills>'
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
    '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
    '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>'
    '</styleSheet>';

// XML 1.0 can't hold most control characters, even escaped.
String _escape(String s) => s
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _column(int index) {
  var n = index + 1;
  var name = '';
  while (n > 0) {
    final rest = (n - 1) % 26;
    name = String.fromCharCode(65 + rest) + name;
    n = (n - 1) ~/ 26;
  }
  return name;
}

String _cell(Object? value, int column, int row, {bool bold = false}) {
  if (value == null) return '';
  final ref = '${_column(column)}$row';
  final style = bold ? ' s="1"' : '';
  if (value is num && value.isFinite) return '<c r="$ref"$style><v>$value</v></c>';
  return '<c r="$ref"$style t="inlineStr"><is><t xml:space="preserve">'
      '${_escape('$value')}</t></is></c>';
}

String _sheetXml(XlsxSheet sheet) {
  final out = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
      '<sheetData><row r="1">');
  for (var c = 0; c < sheet.header.length; c++) {
    out.write(_cell(sheet.header[c], c, 1, bold: true));
  }
  out.write('</row>');
  for (var r = 0; r < sheet.rows.length; r++) {
    out.write('<row r="${r + 2}">');
    final row = sheet.rows[r];
    for (var c = 0; c < row.length; c++) {
      out.write(_cell(row[c], c, r + 2));
    }
    out.write('</row>');
  }
  out.write('</sheetData></worksheet>');
  return out.toString();
}

/// Excel refuses a sheet name over 31 characters or holding one of these, and
/// repeats of the same name.
List<String> _sheetNames(List<XlsxSheet> sheets) {
  final used = <String>{};
  return [
    for (final s in sheets)
      () {
        final clean = s.name.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').trim();
        var name = clean.length > 31 ? clean.substring(0, 31) : clean;
        for (var n = 2; !used.add(name.toLowerCase()); n++) {
          final suffix = ' $n';
          final room = 31 - suffix.length;
          name = (clean.length > room ? clean.substring(0, room) : clean) + suffix;
        }
        return name;
      }(),
  ];
}

/// A minimal .xlsx. Written by hand because it only takes the zip library the
/// app already has, and that works the same on Android, iOS and Web.
Uint8List buildXlsx(List<XlsxSheet> sheets) {
  final archive = Archive();
  void add(String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  final names = _sheetNames(sheets);
  final types = StringBuffer(_contentTypeHead);
  final workbook = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>');
  final rels = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
  for (var i = 0; i < sheets.length; i++) {
    final n = i + 1;
    types.write('<Override PartName="/xl/worksheets/sheet$n.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>');
    workbook.write('<sheet name="${_escape(names[i])}" sheetId="$n" r:id="rId$n"/>');
    rels.write('<Relationship Id="rId$n" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
        'Target="worksheets/sheet$n.xml"/>');
    add('xl/worksheets/sheet$n.xml', _sheetXml(sheets[i]));
  }
  rels.write('<Relationship Id="rId${sheets.length + 1}" '
      'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
      'Target="styles.xml"/></Relationships>');
  types.write('</Types>');
  workbook.write('</sheets></workbook>');

  add('[Content_Types].xml', types.toString());
  add('_rels/.rels', _rootRels);
  add('xl/workbook.xml', workbook.toString());
  add('xl/_rels/workbook.xml.rels', rels.toString());
  add('xl/styles.xml', _styles);
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
