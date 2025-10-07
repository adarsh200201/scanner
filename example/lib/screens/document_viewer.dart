import 'package:flutter/material.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';

import '../widgets/full_frame_pdf_viewer.dart';
import '../services/pdf_service.dart';

class DocumentViewer extends StatefulWidget {
  final String documentTitle;
  final String? filePath;
  final String? content;
  final List<String>? imagePaths;

  const DocumentViewer({
    Key? key,
    required this.documentTitle,
    this.filePath,
    this.content,
    this.imagePaths,
  }) : super(key: key);

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  late String _documentTitle;
  int _currentImageIndex = 0;
  bool _showOverview = false;
  final PageController _imagePageController = PageController();
  int _pdfReloadToken = 0;

  @override
  void initState() {
    super.initState();
    _documentTitle = widget.documentTitle;
    _showOverview = (widget.imagePaths != null && widget.imagePaths!.length > 1);
    print('DocumentViewer - Title: ${widget.documentTitle}');
    print('DocumentViewer - FilePath: ${widget.filePath}');
    print('DocumentViewer - Content: ${widget.content}');
    print('DocumentViewer - ImagePaths: ${widget.imagePaths}');
  }

  bool _isPdfPath(String? p) => (p?.toLowerCase().endsWith('.pdf') ?? false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _documentTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditTitleDialog,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: ((widget.filePath?.toLowerCase().endsWith('.pdf') ?? false) || _getTotalPages() <= 1)
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ((widget.filePath?.toLowerCase().endsWith('.pdf') ?? false) || _getTotalPages() <= 1) ? Colors.transparent : Colors.black,
                borderRadius: BorderRadius.circular(((widget.filePath?.toLowerCase().endsWith('.pdf') ?? false) || _getTotalPages() <= 1) ? 0 : 8),
              ),
              child: _showOverview ? _buildOverviewGrid() : Stack(
                children: [
                  _buildDocumentContent(),
                  if (_getTotalPages() > 1)
                    Positioned(
                      top: 12,
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
                            '${_currentImageIndex + 1} / ${_getTotalPages()}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentContent() {
    print('Building document content:');
    print('File path: ${widget.filePath}');
    print('Content: ${widget.content}');
    print('Image paths: ${widget.imagePaths}');
    
    // If we have multiple image paths, display them
    if (widget.imagePaths != null && widget.imagePaths!.isNotEmpty) {
      final paths = widget.imagePaths!;
      return PageView.builder(
        controller: _imagePageController,
        onPageChanged: (i) => setState(() => _currentImageIndex = i),
        itemCount: paths.length,
        itemBuilder: (context, index) {
          final imgPath = paths[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(_getTotalPages() <= 1 ? 0 : 8),
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.file(
                _resolveFile(imgPath),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  print('Image load error: $error');
                  return _buildErrorWidget('Unable to preview image');
                },
              ),
            ),
          );
        },
      );
    }
    
    // If we have a file path, try to display the file
    if (widget.filePath != null && widget.filePath!.isNotEmpty) {
      final file = widget.filePath!.startsWith('file://')
          ? File.fromUri(Uri.parse(widget.filePath!))
          : File(widget.filePath!);
      print('File exists: ${file.existsSync()}');
      
      if (file.existsSync()) {
        // Check if it's an image file
        if (widget.filePath!.toLowerCase().endsWith('.jpg') ||
            widget.filePath!.toLowerCase().endsWith('.jpeg') ||
            widget.filePath!.toLowerCase().endsWith('.png')) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImageViewer(
                    imagePath: widget.filePath!,
                    title: widget.documentTitle,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_getTotalPages() <= 1 ? 0 : 8),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 5.0,
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    print('Image load error: $error');
                    return _buildErrorWidget('Unable to preview image');
                  },
                ),
              ),
            ),
          );
        } else if (widget.filePath!.toLowerCase().endsWith('.pdf')) {
          return FullFramePdfViewer(
            key: ValueKey(_pdfReloadToken),
            file: file,
            padding: const EdgeInsets.all(8),
          );
        } else if (widget.filePath!.toLowerCase().endsWith('.txt')) {
          // Do not render text section; show a simple placeholder
          return _buildErrorWidget('No preview available');
        }
      } else {
        print('File does not exist: ${widget.filePath}');
      }
    }

    // Do not render text content section
    if (widget.content != null && widget.content!.isNotEmpty) {
      return _buildErrorWidget('No preview available');
    }

    // Fallback: show no content message
    return _buildErrorWidget('No content available');
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Document: ${widget.documentTitle}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  File _resolveFile(String path) {
    if (path.startsWith('file://')) {
      return File.fromUri(Uri.parse(path));
    }
    return File(path);
  }

  Widget _buildOverviewGrid() {
    final images = widget.imagePaths ?? const <String>[];
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final path = images[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentImageIndex = index;
              _showOverview = false;
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _resolveFile(path),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageViewer(String imagePath) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(
              imagePath: imagePath,
              title: _documentTitle,
              currentIndex: _currentImageIndex,
              totalPages: _getTotalPages(),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_getTotalPages() <= 1 ? 0 : 8),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.file(
            _resolveFile(imagePath),
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('Image load error: $error');
              return _buildErrorWidget('Unable to preview image');
            },
          ),
        ),
      ),
    );
  }

  int _getTotalPages() {
    if (widget.imagePaths != null && widget.imagePaths!.isNotEmpty) {
      return widget.imagePaths!.length;
    }
    return 1;
  }

  void _previousPage() {
    if (_currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
      });
    }
  }

  void _nextPage() {
    if (_currentImageIndex < _getTotalPages() - 1) {
      setState(() {
        _currentImageIndex++;
      });
    }
  }

  void _showEditTitleDialog() {
    final TextEditingController controller = TextEditingController(text: _documentTitle);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit Document Title', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter document title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _documentTitle = controller.text.trim();
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title updated successfully!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B7FFF)),
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Document Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            if (_isPdfPath(widget.filePath))
              ListTile(
                leading: const Icon(Icons.post_add, color: Color(0xFF5B7FFF)),
                title: const Text('Add More Pages'),
                onTap: () async {
                  Navigator.pop(context);
                  await _addMorePages();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF5B7FFF)),
                title: const Text('Save as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _saveToPDF();
                },
              ),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF5B7FFF)),
              title: const Text('Share Document'),
              onTap: () {
                Navigator.pop(context);
                _shareDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF5B7FFF)),
              title: const Text('Edit Title'),
              onTap: () {
                Navigator.pop(context);
                _showEditTitleDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Document', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF saved successfully!')),
    );
  }

  Future<void> _addMorePages() async {
    try {
      if (widget.filePath == null || !_isPdfPath(widget.filePath)) return;
      final scanner = FlutterDocScanner();
      final res = await scanner.getScannedDocumentAsImages(page: 20);
      if (res == null) return;
      final uris = (res['Uri'] as List?)?.cast<String>() ?? const <String>[];
      if (uris.isEmpty) return;

      final existingPdfPath = widget.filePath!.startsWith('file://')
          ? File.fromUri(Uri.parse(widget.filePath!)).path
          : widget.filePath!;

      // Rasterize existing PDF to temp PNG files
      final existing = File(existingPdfPath);
      if (!await existing.exists()) return;
      final bytes = await existing.readAsBytes();
      final tmpDir = await getTemporaryDirectory();
      final existingPngs = <String>[];
      int i = 0;
      await for (final page in Printing.raster(bytes, dpi: 144)) {
        final png = await page.toPng();
        final outPath = '${tmpDir.path}/__pdf_existing_$i.png';
        await File(outPath).writeAsBytes(png);
        existingPngs.add(outPath);
        i++;
      }

      // Normalize new image paths
      final newImages = uris
          .map((p) => p.startsWith('file://') ? File.fromUri(Uri.parse(p)).path : p)
          .toList(growable: false);

      final allImages = [...existingPngs, ...newImages];
      // Rebuild PDF at the same path
      final successPath = await PdfService.convertImagesToPdfAtPath(
        imagePaths: allImages,
        outputPath: existingPdfPath,
        quality: 'Regular',
      );

      // Cleanup temps
      for (final p in existingPngs) {
        try { await File(p).delete(); } catch (_) {}
      }

      if (successPath != null) {
        setState(() => _pdfReloadToken++);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pages added to PDF')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to append pages')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _shareDocument() async {
    try {
      final paths = <String>[];
      if (widget.imagePaths != null && widget.imagePaths!.isNotEmpty) {
        paths.addAll(widget.imagePaths!);
      } else if (widget.filePath != null && widget.filePath!.isNotEmpty) {
        paths.add(widget.filePath!);
      }
      if (paths.isEmpty) return;
      final xfiles = paths
          .map((p) => p.startsWith('file://') ? File.fromUri(Uri.parse(p)).path : p)
          .map((p) => XFile(p))
          .toList();
      await Share.shareXFiles(xfiles, text: _documentTitle);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share: $e')),
      );
    }
  }

  void _showDeleteConfirmation() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delete Document', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 12),
            Text('Are you sure you want to delete "$_documentTitle"?', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context); // Go back to previous screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Document deleted successfully!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final String title;
  final int currentIndex;
  final int totalPages;

  const FullScreenImageViewer({
    Key? key,
    required this.imagePath,
    required this.title,
    this.currentIndex = 0,
    this.totalPages = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$title (${currentIndex + 1}/$totalPages)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () async {
              final path = imagePath.startsWith('file://')
                  ? File.fromUri(Uri.parse(imagePath)).path
                  : imagePath;
              await Share.shareXFiles([XFile(path)], text: title);
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            (imagePath.startsWith('file://')) ? File.fromUri(Uri.parse(imagePath)) : File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
