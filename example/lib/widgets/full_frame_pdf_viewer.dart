import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// A full-frame PDF viewer that renders each page as an image and
/// displays them in a vertically scrollable list with pinch-to-zoom.
class FullFramePdfViewer extends StatefulWidget {
  final File file;
  final double dpi;
  final EdgeInsets padding;
  final Color backgroundColor;

  const FullFramePdfViewer({
    super.key,
    required this.file,
    this.dpi = 96,
    this.padding = EdgeInsets.zero,
    this.backgroundColor = Colors.black,
  });

  @override
  State<FullFramePdfViewer> createState() => _FullFramePdfViewerState();
}

class _FullFramePdfViewerState extends State<FullFramePdfViewer> {
  final PageController _pageController = PageController();
  final TransformationController _transformController = TransformationController();
  int _currentPage = 0;
  bool _isZoomed = false;
  final List<Uint8List> _pages = <Uint8List>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final double safeDpi = Platform.isAndroid ? (widget.dpi > 96 ? 96 : widget.dpi) : widget.dpi;
    _startRasterization(widget.file, safeDpi);
  }

  @override
  void didUpdateWidget(covariant FullFramePdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path || oldWidget.dpi != widget.dpi) {
      final double safeDpi = Platform.isAndroid ? (widget.dpi > 96 ? 96 : widget.dpi) : widget.dpi;
      _startRasterization(widget.file, safeDpi);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Unable to render PDF: $_error',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_pages.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pages = _pages;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSinglePage = pages.length == 1;
        final pad = widget.padding;
        final availableWidth = constraints.maxWidth - pad.horizontal;
        final availableHeight = constraints.maxHeight - pad.vertical;
        return Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pages.isEmpty ? 1 : pages.length,
              onPageChanged: (i) {
                setState(() {
                  _currentPage = i;
                  _transformController.value = Matrix4.identity();
                });
              },
              itemBuilder: (context, index) {
                if (pages.isEmpty || index >= pages.length) {
                  return Container(
                    color: widget.backgroundColor,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                }
                final bytes = pages[index];
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: widget.backgroundColor,
                  padding: widget.padding,
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    panEnabled: false,
                    scaleEnabled: true,
                    boundaryMargin: EdgeInsets.zero,
                    clipBehavior: Clip.none,
                    constrained: true,
                    onInteractionUpdate: (_) {
                      final scale = _transformController.value.getMaxScaleOnAxis();
                      final z = scale > 1.01;
                      if (z != _isZoomed) setState(() => _isZoomed = z);
                    },
                    onInteractionEnd: (_) {
                      final scale = _transformController.value.getMaxScaleOnAxis();
                      final z = scale > 1.01;
                      if (z != _isZoomed) setState(() => _isZoomed = z);
                    },
                    minScale: 1.0,
                    maxScale: 15.0,
                    child: Center(
                      child: SizedBox(
                        width: availableWidth,
                        height: availableHeight,
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (pages.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${pages.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _startRasterization(File file, double dpi) async {
    setState(() {
      _loading = true;
      _error = null;
      _pages.clear();
      _currentPage = 0;
      _transformController.value = Matrix4.identity();
    });
    try {
      final bytes = await file.readAsBytes();
      final stream = Printing.raster(bytes, dpi: dpi);
      await for (final page in stream) {
        final png = await page.toPng();
        if (!mounted) return;
        setState(() {
          _pages.add(png);
        });
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (dpi > 72) {
        await _startRasterization(file, 72);
        return;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

}
