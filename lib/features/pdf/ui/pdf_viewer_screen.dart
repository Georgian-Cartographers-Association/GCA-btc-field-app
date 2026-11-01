import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/constants.dart';
import '../../settings/domain/settings_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const PdfViewerScreen({super.key, this.embedded = false});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final PdfViewerController _ctrl = PdfViewerController();
  bool _loaded = false;

  bool _searchOpen = false;
  final _searchCtrl = TextEditingController();
  PdfTextSearchResult? _searchResult;
  int _searchTotal = 0;
  int _searchCurrent = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final saved = ref.read(settingsProvider).pdfPage;
      if (saved > 0 && _loaded) _ctrl.jumpToPage(saved);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchResult?.clear();
    super.dispose();
  }

  void _onPageChanged(PdfPageChangedDetails d) {
    ref.read(settingsProvider.notifier).savePdfPage(d.newPageNumber);
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) _clearSearch();
    });
  }

  void _clearSearch() {
    _searchResult?.clear();
    _searchCtrl.clear();
    setState(() {
      _searchResult = null;
      _searchTotal = 0;
      _searchCurrent = 0;
    });
  }

  void _doSearch(String query) {
    if (query.isEmpty) {
      _clearSearch();
      return;
    }
    _searchResult?.clear();
    final result = _ctrl.searchText(query);
    result.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchTotal = result.totalInstanceCount;
        _searchCurrent = result.currentInstanceIndex;
      });
    });
    setState(() => _searchResult = result);
  }

  void _nextResult() {
    _searchResult?.nextInstance();
    setState(() => _searchCurrent = _searchResult?.currentInstanceIndex ?? 0);
  }

  void _prevResult() {
    _searchResult?.previousInstance();
    setState(() => _searchCurrent = _searchResult?.currentInstanceIndex ?? 0);
  }

  void _zoomIn() => _ctrl.zoomLevel = (_ctrl.zoomLevel + 0.25).clamp(1.0, 3.0);
  void _zoomOut() =>
      _ctrl.zoomLevel = (_ctrl.zoomLevel - 0.25).clamp(1.0, 3.0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saved = ref.read(settingsProvider).pdfPage;

    final viewer = SfPdfViewer.asset(
      AppConstants.pdfAssetPath,
      controller: _ctrl,
      initialPageNumber: saved > 0 ? saved : 1,
      onPageChanged: _onPageChanged,
      onDocumentLoaded: (_) => setState(() => _loaded = true),
      canShowScrollHead: !widget.embedded,
      canShowScrollStatus: true,
      enableTextSelection: true,
    );

    if (widget.embedded) return viewer;

    return Scaffold(
      appBar: AppBar(
        title:
            _searchOpen ? _searchBar() : Text(l10n.methodology),
        actions: [
          if (_loaded && !_searchOpen) ...[
            IconButton(
              icon: const Icon(Icons.zoom_in),
              tooltip: l10n.zoomIn,
              onPressed: _zoomIn,
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: l10n.zoomOutSmall,
              onPressed: _zoomOut,
            ),
          ],
          if (_loaded)
            IconButton(
              icon: Icon(_searchOpen ? Icons.search_off : Icons.search),
              tooltip: _searchOpen ? l10n.closeSearch : l10n.search,
              onPressed: _toggleSearch,
            ),
          if (_loaded && !_searchOpen)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: l10n.pageOf(_ctrl.pageNumber, _ctrl.pageCount),
              onPressed: _showPageJump,
            ),
        ],
        bottom: (_searchOpen && _searchResult != null)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Container(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        _searchTotal > 0
                            ? '$_searchCurrent / $_searchTotal'
                            : l10n.notFound,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _searchTotal > 0 ? _prevResult : null,
                        tooltip: l10n.previous,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _searchTotal > 0 ? _nextResult : null,
                        tooltip: l10n.next,
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: viewer,
    );
  }

  Widget _searchBar() => TextField(
        controller: _searchCtrl,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchEllipsis,
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
        onSubmitted: _doSearch,
        onChanged: (v) {
          if (v.isEmpty) _clearSearch();
        },
      );

  void _showPageJump() {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: _ctrl.pageNumber.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.goToPage),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.pageRange(_ctrl.pageCount),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              final p = int.tryParse(ctrl.text);
              if (p != null && p >= 1 && p <= _ctrl.pageCount) {
                _ctrl.jumpToPage(p);
              }
              Navigator.pop(ctx);
            },
            child: Text(l10n.goAction),
          ),
        ],
      ),
    );
  }
}
