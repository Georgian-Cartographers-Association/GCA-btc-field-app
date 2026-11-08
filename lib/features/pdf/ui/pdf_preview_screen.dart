import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/app_messenger.dart';
import '../../../data/services/export_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/btk_record.dart';

/// Shows the PDF of [records], so it can be checked before it is shared or saved.
class PdfPreviewScreen extends StatefulWidget {
  final List<BtkRecord> records;
  final Future<Uint8List> Function(List<BtkRecord>) buildPdf;

  /// Named after the records when left out.
  final String? filename;

  const PdfPreviewScreen({
    super.key,
    required this.records,
    this.buildPdf = ExportService.buildPdf,
    this.filename,
  });

  static Future<void> open(BuildContext context, List<BtkRecord> records) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => PdfPreviewScreen(records: records),
      ));

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  Uint8List? _bytes;
  bool _failed = false;
  bool _busy = false;

  String get _filename => widget.filename ?? ExportService.pdfFilename(widget.records);

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    setState(() {
      _bytes = null;
      _failed = false;
    });
    try {
      final bytes = await widget.buildPdf(widget.records);
      if (mounted) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  // Only one share or save at a time, since each opens a system screen.
  Future<void> _run(Future<void> Function(Uint8List bytes) action) async {
    setState(() => _busy = true);
    try {
      await action(_bytes!);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() => _run((bytes) async {
        final l10n = AppLocalizations.of(context)!;
        try {
          await ExportService.sharePdf(bytes, _filename, l10n);
        } catch (_) {
          AppMessenger.showError((l10n) => l10n.shareFailed);
        }
      });

  Future<void> _save() =>
      _run((bytes) => ExportService.savePdf(bytes, _filename, context));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bytes = _bytes;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pdfPreview)),
      body: bytes != null
          ? SfPdfViewer.memory(bytes, canShowScrollHead: true)
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _failed
                      ? [
                          Text(l10n.pdfBuildFailed, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton(onPressed: _build, child: Text(l10n.retry)),
                        ]
                      : [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(l10n.pdfPreparing),
                        ],
                ),
              ),
            ),
      bottomNavigationBar: bytes == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.save_alt_outlined),
                        label: Text(l10n.saveAsFile),
                        onPressed: _busy ? null : _save,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.share_outlined),
                        label: Text(l10n.share),
                        onPressed: _busy ? null : _share,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
