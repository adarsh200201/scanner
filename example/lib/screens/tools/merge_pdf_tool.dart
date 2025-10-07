import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:reorderables/reorderables.dart';
import '../../services/storage_service.dart';
import 'package:printing/printing.dart';
import '../document_viewer.dart';
import 'browse_pdf_tool.dart';
import 'dart:io';

class MergePdfTool extends StatefulWidget {
  const MergePdfTool({Key? key}) : super(key: key);

  @override
  State<MergePdfTool> createState() => _MergePdfToolState();
}

class _MergePdfToolState extends State<MergePdfTool> {
  List<Map<String, dynamic>> _history = [];
  List<PdfFileItem> _selectedPdfs = [];
  bool _isProcessing = false;
  double _progress = 0.0;
  String _outputFileName = '';

  @override
  void initState() {
    super.initState();
    _generateDefaultFileName();
    _loadHistory();
  }

  void _generateDefaultFileName() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    _outputFileName = 'Merged_Document_${formatter.format(now)}';
  }

  Future<void> _pickPdfFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.path != null) {
            final pdfFile = File(file.path!);
            final size = await pdfFile.length();
            final pages = await _getPdfPageCount(pdfFile);
            
            setState(() {
              _selectedPdfs.add(PdfFileItem(
                file: pdfFile,
                name: file.name,
                size: size,
                pageCount: pages,
              ));
            });
          }
        }
      }
    } catch (e) {
      _showError('Error picking files: $e');
    }
  }

  Future<int> _getPdfPageCount(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final count = document.pages.count;
      document.dispose();
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _mergePdfs() async {
    if (_selectedPdfs.length < 2) {
      _showError('Please select at least 2 PDF files to merge');
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
    });

    try {
      // Create a new PDF document
      final PdfDocument mergedDocument = PdfDocument();

      int processedPages = 0;
      final totalPages = _getTotalPages();

      for (int i = 0; i < _selectedPdfs.length; i++) {
        final pdfFile = _selectedPdfs[i];
        final bytes = await pdfFile.file.readAsBytes();
        final document = PdfDocument(inputBytes: bytes);

        // Import pages preserving original size and margins using templates
        PdfSection? section;
        for (int j = 0; j < document.pages.count; j++) {
          final template = document.pages[j].createTemplate();
          if (section == null || section.pageSettings.size != template.size) {
            section = mergedDocument.sections!.add();
            section.pageSettings.size = template.size;
            section.pageSettings.margins.all = 0;
          }
          section.pages.add().graphics.drawPdfTemplate(
            template,
            Offset.zero,
            template.size,
          );
          processedPages++;
          setState(() {
            _progress = processedPages / totalPages;
          });
        }

        document.dispose();
      }

      // Save merged PDF
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/$_outputFileName.pdf';
      final file = File(outputPath);
      await file.writeAsBytes(await mergedDocument.save());
      mergedDocument.dispose();

      final size = await file.length();

      // Generate first-page preview image for thumbnails
      String? previewPath;
      try {
        final bytes = await file.readAsBytes();
        final raster = await Printing.raster(bytes, pages: const [0], dpi: 100).first;
        final png = await raster.toPng();
        final previewFile = File('${outputPath.replaceAll('.pdf', '')}_preview.jpg');
        await previewFile.writeAsBytes(png, flush: true);
        previewPath = previewFile.path;
      } catch (_) {}

      await StorageService.addExternalFile(
        name: _outputFileName,
        filePath: outputPath,
        fileSize: size,
        type: 'document',
        previewImagePath: previewPath,
      );
      await StorageService.addHistory('merge', {
        'time': DateTime.now().toIso8601String(),
        'name': '$_outputFileName.pdf',
        'path': outputPath,
        'size': size,
        'inputs': _selectedPdfs.map((e) => {'name': e.name, 'pages': e.pageCount, 'size': e.size}).toList(),
        'totalPages': _getTotalPages(),
      });
      await _loadHistory();

      setState(() {
        _isProcessing = false;
      });

      // Show success screen
      _showSuccessDialog(outputPath, size);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error merging PDFs: $e');
    }
  }

  int _getTotalPages() {
    return _selectedPdfs.fold(0, (sum, pdf) => sum + pdf.pageCount);
  }

  Future<void> _loadHistory() async {
    final h = await StorageService.getHistory('merge');
    if (mounted) setState(() => _history = h);
  }

  Widget _buildHistorySection() {
    final recent = _history.take(3).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Merges', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...recent.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, color: Color(0xFF5B7FFF)),
                title: Text(e['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(_formatFileSize((e['size'] ?? 0) as int)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final p = e['path'] as String?;
                  if (p != null) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DocumentViewer(documentTitle: e['name'] ?? 'Merged Document', filePath: p),
                    ));
                  }
                },
              )),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessDialog(String filePath, int fileSize) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              'PDF Merged Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Saved to My Documents. You can find it there anytime.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: $_outputFileName.pdf'),
                  Text('Size: ${_formatFileSize(fileSize)}'),
                  Text('Pages: ${_getTotalPages()}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedPdfs.clear();
                        _generateDefaultFileName();
                      });
                    },
                    child: const Text('Merge Another'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const BrowsePdfTool(),
                      ));
                    },
                    child: const Text('Open My Documents'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B7FFF),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Merge PDF',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Merge PDF'),
                  content: const Text(
                    'Select 2 or more PDF files to combine them into a single PDF document. '
                    'You can reorder files by dragging them.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _selectedPdfs.isEmpty
                    ? _buildEmptyState()
                    : _buildFileList(),
              ),
              if (_history.isNotEmpty) _buildHistorySection(),
              if (_selectedPdfs.isNotEmpty) _buildBottomBar(),
            ],
          ),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              size: 60,
              color: Color(0xFF5B7FFF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select 2 or more PDFs to merge',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickPdfFiles,
            icon: const Icon(Icons.add),
            label: const Text('Add PDF Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B7FFF),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return ReorderableColumn(
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _selectedPdfs.removeAt(oldIndex);
          _selectedPdfs.insert(newIndex, item);
        });
      },
      children: [
        for (int i = 0; i < _selectedPdfs.length; i++)
          Container(
            key: ValueKey(_selectedPdfs[i].name),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.drag_handle, color: Colors.grey),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPdfs[i].name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedPdfs[i].pageCount} pages • ${_formatFileSize(_selectedPdfs[i].size)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedPdfs.removeAt(i);
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedPdfs.length} PDFs selected • ${_getTotalPages()} pages total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickPdfFiles,
                  icon: const Icon(Icons.add),
                  label: const Text('Add More'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPdfs.length >= 2 ? _mergePdfs : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B7FFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Merge PDFs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.merge_type,
                size: 60,
                color: Color(0xFF5B7FFF),
              ),
              const SizedBox(height: 24),
              Text(
                'Merging PDFs...',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B7FFF)),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PdfFileItem {
  final File file;
  final String name;
  final int size;
  final int pageCount;

  PdfFileItem({
    required this.file,
    required this.name,
    required this.size,
    required this.pageCount,
  });
}
