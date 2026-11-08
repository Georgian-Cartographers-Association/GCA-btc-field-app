// Builds assets/pdf/methodology_en.pdf, the English field guide shown in the
// app when its language is English.
//
// The guide is an original, abridged text written for the app. It is not a
// translation of the Georgian methodology, which stays the full reference.
//
// Run from the project root:
//   dart run tool/methodology_en/build.dart
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'content.dart';

const _out = 'assets/pdf/methodology_en.pdf';

final _accent = PdfColor.fromHex('#2E5E4E');
final _muted = PdfColor.fromHex('#5F6B66');
final _noteBg = PdfColor.fromHex('#EEF3F0');
final _rule = PdfColor.fromHex('#C9D3CE');

Future<void> main() async {
  // The contents page comes first but needs the page numbers of headings that
  // come later, so the document is laid out once to find them.
  final first = _build(const {});
  await first.save();
  final pages = <String, int>{};
  void walk(PdfOutline o) {
    for (final c in o.outlines) {
      if (c.title != null) pages[c.title!] = int.tryParse(c.page ?? "") ?? 0;
      walk(c);
    }
  }

  walk(first.document.outline);

  await File(_out).writeAsBytes(await _build(pages).save());
  stdout.writeln('Wrote $_out');
}

pw.Document _build(Map<String, int> pages) {
  final doc = pw.Document(
    title: guideTitle,
    author: 'Georgian Cartographers Association',
    subject: guideSubtitle,
    theme:
        pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          italic: pw.Font.helveticaOblique(),
          boldItalic: pw.Font.helveticaBoldOblique(),
        ).copyWith(
          defaultTextStyle: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.6),
        ),
  );

  const format = PdfPageFormat.a5;
  const margin = pw.EdgeInsets.fromLTRB(36, 40, 36, 40);

  doc.addPage(
    pw.Page(pageFormat: format, margin: margin, build: (_) => _cover()),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: margin,
      build: (_) => [
        _h(1, 'Contents', outline: false),
        pw.SizedBox(height: 6),
        for (final b in guide)
          if (b is Chapter)
            _tocLine(b.title, pages[b.title], bold: true)
          else if (b is Section)
            _tocLine(b.title, pages[b.title]),
      ],
    ),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: margin,
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          '$guideShortTitle  ·  ${context.pageNumber}',
          style: pw.TextStyle(fontSize: 7.5, color: _muted),
        ),
      ),
      build: (_) => [for (final b in guide) ..._block(b)],
    ),
  );

  return doc;
}

pw.Widget _tocLine(String title, int? page, {bool bold = false}) => pw.Padding(
  padding: pw.EdgeInsets.only(top: bold ? 5 : 1, left: bold ? 0 : 10),
  child: pw.Row(
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: bold ? 9.5 : 8.5,
          fontWeight: bold ? pw.FontWeight.bold : null,
        ),
      ),
      pw.SizedBox(width: 6),
      pw.Expanded(
        child: pw.Divider(borderStyle: pw.BorderStyle.dotted, thickness: 0.3),
      ),
      pw.SizedBox(width: 6),
      pw.Text(
        page == null ? '' : '$page',
        style: const pw.TextStyle(fontSize: 8.5),
      ),
    ],
  ),
);

pw.Widget _cover() => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.SizedBox(height: 60),
    pw.Container(width: 40, height: 3, color: _accent),
    pw.SizedBox(height: 14),
    pw.Text(
      guideTitle,
      style: pw.TextStyle(
        fontSize: 22,
        fontWeight: pw.FontWeight.bold,
        color: _accent,
      ),
    ),
    pw.SizedBox(height: 8),
    pw.Text(
      guideSubtitle,
      style: pw.TextStyle(fontSize: 11, color: _muted, lineSpacing: 3),
    ),
    pw.Spacer(),
    _note(coverNote),
    pw.SizedBox(height: 16),
    pw.Text(
      'Georgian Cartographers Association',
      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    ),
    pw.Text(
      'BTC Field App  ·  $guideEdition',
      style: pw.TextStyle(fontSize: 8.5, color: _muted),
    ),
  ],
);

pw.Widget _h(int level, String text, {bool outline = true}) {
  final size = switch (level) {
    1 => 15.0,
    2 => 11.5,
    _ => 10.0,
  };
  final style = pw.TextStyle(
    fontSize: size,
    fontWeight: pw.FontWeight.bold,
    color: level == 3 ? PdfColors.black : _accent,
  );
  final top = switch (level) {
    1 => 0.0,
    2 => 10.0,
    _ => 6.0,
  };
  final child = pw.Padding(
    padding: pw.EdgeInsets.only(top: top, bottom: level == 1 ? 8 : 4),
    child: pw.Text(text, style: style),
  );
  if (!outline || level == 3) return child;
  return pw.Header(
    level: level - 1,
    text: text,
    title: text,
    textStyle: style,
    decoration: const pw.BoxDecoration(),
    padding: pw.EdgeInsets.zero,
    margin: pw.EdgeInsets.zero,
    child: child,
  );
}

pw.Widget _note(String text) => pw.Container(
  width: double.infinity,
  padding: const pw.EdgeInsets.all(8),
  decoration: pw.BoxDecoration(
    color: _noteBg,
    border: pw.Border(left: pw.BorderSide(color: _accent, width: 2)),
  ),
  child: pw.Text(text, style: const pw.TextStyle(fontSize: 8.5)),
);

List<pw.Widget> _block(Block b) => switch (b) {
  Chapter(:final title) => [
    pw.NewPage(freeSpace: 200),
    pw.SizedBox(height: 14),
    _h(1, title),
  ],
  Section(:final title) => [pw.NewPage(freeSpace: 90), _h(2, title)],
  Sub(:final title) => [pw.NewPage(freeSpace: 70), _h(3, title)],
  Para(:final text) => [
    pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(text, textAlign: pw.TextAlign.justify),
    ),
  ],
  Bullets(:final items) => [
    for (final item in items)
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 4, bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 3,
              height: 3,
              margin: const pw.EdgeInsets.only(top: 5, right: 7),
              decoration: pw.BoxDecoration(
                color: _accent,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(child: _rich(item)),
          ],
        ),
      ),
    pw.SizedBox(height: 4),
  ],
  Table(:final header, :final rows, :final widths) => [
    pw.NewPage(freeSpace: 60),
    pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2, bottom: 8),
      child: pw.TableHelper.fromTextArray(
        headers: header,
        data: rows,
        columnWidths: widths == null
            ? null
            : {
                for (var i = 0; i < widths.length; i++)
                  i: pw.FlexColumnWidth(widths[i]),
              },
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: _accent,
        ),
        cellStyle: const pw.TextStyle(fontSize: 8, lineSpacing: 1),
        headerDecoration: pw.BoxDecoration(color: _noteBg),
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _rule, width: 0.5),
          bottom: pw.BorderSide(color: _rule, width: 0.5),
        ),
      ),
    ),
  ],
  Note(:final text) => [
    pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2, bottom: 8),
      child: _note(text),
    ),
  ],
};

/// "Term: explanation" bullets show the term in bold.
pw.Widget _rich(String item) {
  final i = item.indexOf(': ');
  if (i <= 0 || i > 48) return pw.Text(item);
  return pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: item.substring(0, i + 1),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.TextSpan(text: item.substring(i + 1)),
      ],
    ),
  );
}
