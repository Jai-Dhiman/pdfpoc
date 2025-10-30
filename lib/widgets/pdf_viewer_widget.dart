import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdfx/pdfx.dart';
import '../providers/app_state.dart';
import 'bar_overlay_painter.dart';
import 'annotation_painter.dart';
import 'text_annotation_painter.dart';
import 'bar_context_menu.dart';

class PDFViewerWidget extends StatefulWidget {
  const PDFViewerWidget({super.key});

  @override
  State<PDFViewerWidget> createState() => _PDFViewerWidgetState();
}

class _PDFViewerWidgetState extends State<PDFViewerWidget> {
  PdfController? _pdfController;
  bool _isLoading = true;
  int? _contextMenuBarNumber;
  Offset? _contextMenuPosition;

  @override
  void initState() {
    super.initState();
    _initializePdf();
  }

  Future<void> _initializePdf() async {
    try {
      if (mounted) {
        setState(() {
          _pdfController = PdfController(
            document: PdfDocument.openAsset('assets/data/unsospiro.pdf'),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_pdfController == null) {
      return const Center(
        child: Text('Failed to load PDF'),
      );
    }

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              return _handleKeyPress(context, event.logicalKey);
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              PdfView(
                controller: _pdfController!,
                scrollDirection: Axis.vertical,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.grey,
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                onTapDown: (details) {
                  _handleTap(context, details.localPosition);
                },
                onLongPressStart: (details) {
                  _handleLongPress(context, details.localPosition);
                },
                onSecondaryTapDown: (details) {
                  _handleLongPress(context, details.localPosition);
                },
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: BarOverlayPainter(
                        bars: appState.bars,
                        currentBarNumber: appState.currentBarNumber,
                      ),
                    ),
                    CustomPaint(
                      painter: TextAnnotationPainter(
                        annotations: appState.getAllTextAnnotations(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: AnnotationPainter(
                appState: appState,
              ),
            ),
            if (_contextMenuBarNumber != null && _contextMenuPosition != null)
              BarContextMenu(
                barNumber: _contextMenuBarNumber!,
                position: _contextMenuPosition!,
                onDismiss: () {
                  setState(() {
                    _contextMenuBarNumber = null;
                    _contextMenuPosition = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  KeyEventResult _handleKeyPress(BuildContext context, LogicalKeyboardKey key) {
    final appState = Provider.of<AppState>(context, listen: false);
    final bars = appState.bars;

    if (bars.isEmpty) return KeyEventResult.ignored;

    final currentBar = appState.currentBarNumber;

    if (key == LogicalKeyboardKey.arrowRight) {
      if (currentBar == null) {
        appState.seekToBarAndPlay(bars.first.barNumber);
      } else {
        final currentIndex = bars.indexWhere((b) => b.barNumber == currentBar);
        if (currentIndex < bars.length - 1) {
          appState.seekToBarAndPlay(bars[currentIndex + 1].barNumber);
        }
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (currentBar == null) {
        appState.seekToBarAndPlay(bars.first.barNumber);
      } else {
        final currentIndex = bars.indexWhere((b) => b.barNumber == currentBar);
        if (currentIndex > 0) {
          appState.seekToBarAndPlay(bars[currentIndex - 1].barNumber);
        }
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.space) {
      if (currentBar != null) {
        appState.seekToBarAndPlay(currentBar);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handleTap(BuildContext context, Offset position) {
    final appState = Provider.of<AppState>(context, listen: false);
    final bar = appState.findBarAtPoint(position.dx, position.dy);

    if (bar != null) {
      if (appState.isQualityControlMode) {
        appState.addBarAnnotation(bar.barNumber, appState.currentQualityLevel);
      } else {
        appState.setCurrentBar(bar.barNumber);
        appState.seekToBarAndPlay(bar.barNumber);
      }
    }
  }

  void _handleLongPress(BuildContext context, Offset position) {
    final appState = Provider.of<AppState>(context, listen: false);
    final bar = appState.findBarAtPoint(position.dx, position.dy);

    if (bar != null) {
      setState(() {
        _contextMenuBarNumber = bar.barNumber;
        _contextMenuPosition = position;
      });
    }
  }
}
