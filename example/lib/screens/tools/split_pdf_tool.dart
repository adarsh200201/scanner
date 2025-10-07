import 'dart:io';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../../services/storage_service.dart';
import '../document_viewer.dart';
import 'browse_pdf_tool.dart';

enum SplitMethod {
  byPageRange,
  extractPages,
  everyXPages,
  equalParts,
  eachPageSeparately,
}

class SplitPdfTool extends StatefulWidget {
  const SplitPdfTool({Key? key}) : super(key: key);

  @override
  State<SplitPdfTool> createState() => _SplitPdfToolState();
}

class _SplitPdfToolState extends State<SplitPdfTool> {
  File? _selectedPdf;
  String? _fileName;
  int _totalPages = 0;
  int _fileSize = 0;
  SplitMethod? _selectedMethod;
  bool _isProcessing = false;
  double _progress = 0.0;

  // For different split methods
  List<bool> _selectedPages = [];
  int _splitEveryPages = 5;
  int _equalParts = 3;
  String _pageRanges = '';

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final size = await file.length();
        final pages = await _getPdfPageCount(file);

        setState(() {
          _selectedPdf = file;
          _fileName = result.files.single.name;
          _fileSize = size;
          _totalPages = pages;
          _selectedPages = List.filled(pages, false);
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
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

  Future<void> _splitPdf() async {
    if (_selectedPdf == null || _selectedMethod == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
    });

    try {
      final bytes = await _selectedPdf!.readAsBytes();
      final sourceDocument = PdfDocument(inputBytes: bytes);
      final directory = await getApplicationDocumentsDirectory();
      final baseName = _fileName!.replaceAll('.pdf', '');

      List<String> createdFiles = [];

      switch (_selectedMethod!) {
        case SplitMethod.byPageRange:
          createdFiles = await _splitByPageRange(sourceDocument, directory.path, baseName);
          break;
        case SplitMethod.extractPages:
          createdFiles = await _extractSelectedPages(sourceDocument, directory.path, baseName);
          break;
        case SplitMethod.everyXPages:
          createdFiles = await _splitEveryXPages(sourceDocument, directory.path, baseName);
          break;
        case SplitMethod.equalParts:
          createdFiles = await _splitIntoEqualParts(sourceDocument, directory.path, baseName);
          break;
        case SplitMethod.eachPageSeparately:
          createdFiles = await _splitEachPageSeparately(sourceDocument, directory.path, baseName);
          break;
      }

      sourceDocument.dispose();

      // Register all created files in library
      for (final p in createdFiles) {
        final name = p.split('/').last.replaceAll('.pdf', '');
        final size = await File(p).length();
        await StorageService.addExternalFile(name: name, filePath: p, fileSize: size, type: 'document');
      }

      setState(() {
        _isProcessing = false;
      });

      _showSuccessDialog(createdFiles);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error splitting PDF: $e');
    }
  }

  Future<List<String>> _splitByPageRange(PdfDocument source, String path, String baseName) async {
    // Parse page ranges like "1-5,8-10,15-20"
    final ranges = _pageRanges.split(',').map((r) => r.trim()).where((r) => r.isNotEmpty).toList();
    List<String> files = [];

    for (int i = 0; i < ranges.length; i++) {
      final range = ranges[i];
      final parts = range.split('-');
      final start = int.parse(parts[0]) - 1;
      final end = parts.length > 1 ? int.parse(parts[1]) - 1 : start;

      final newDoc = PdfDocument();
      for (int page = start; page <= end && page < source.pages.count; page++) {
        final template = source.pages[page].createTemplate();
        newDoc.pages.add().graphics.drawPdfTemplate(template, Offset.zero, template.size);
      }

      final outputPath = '$path/${baseName}_Part_${i + 1}.pdf';
      final file = File(outputPath);
      await file.writeAsBytes(await newDoc.save());
      newDoc.dispose();
      files.add(outputPath);

      setState(() {
        _progress = (i + 1) / ranges.length;
      });
    }

    return files;
  }

  Future<List<String>> _extractSelectedPages(PdfDocument source, String path, String baseName) async {
    final newDoc = PdfDocument();
    int extracted = 0;

    for (int i = 0; i < _selectedPages.length; i++) {
      if (_selectedPages[i]) {
        final template = source.pages[i].createTemplate();
        newDoc.pages.add().graphics.drawPdfTemplate(template, Offset.zero, template.size);
        extracted++;
      }
    }

    final outputPath = '$path/${baseName}_Extracted.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await newDoc.save());
    newDoc.dispose();

    return [outputPath];
  }

  Future<List<String>> _splitEveryXPages(PdfDocument source, String path, String baseName) async {
    List<String> files = [];
    int part = 1;

    for (int i = 0; i < source.pages.count; i += _splitEveryPages) {
      final newDoc = PdfDocument();
      for (int j = i; j < i + _splitEveryPages && j < source.pages.count; j++) {
        final template = source.pages[j].createTemplate();
        newDoc.pages.add().graphics.drawPdfTemplate(template, Offset.zero, template.size);
      }

      final outputPath = '$path/${baseName}_Part_$part.pdf';
      final file = File(outputPath);
      await file.writeAsBytes(await newDoc.save());
      newDoc.dispose();
      files.add(outputPath);

      part++;
      setState(() {
        _progress = (i + _splitEveryPages) / source.pages.count;
      });
    }

    return files;
  }

  Future<List<String>> _splitIntoEqualParts(PdfDocument source, String path, String baseName) async {
    List<String> files = [];
    final pagesPerPart = (source.pages.count / _equalParts).ceil();

    for (int part = 0; part < _equalParts; part++) {
      final startPage = part * pagesPerPart;
      if (startPage >= source.pages.count) break;

      final newDoc = PdfDocument();
      for (int i = startPage; i < startPage + pagesPerPart && i < source.pages.count; i++) {
        final template = source.pages[i].createTemplate();
        newDoc.pages.add().graphics.drawPdfTemplate(template, Offset.zero, template.size);
      }

      final outputPath = '$path/${baseName}_Part_${part + 1}.pdf';
      final file = File(outputPath);
      await file.writeAsBytes(await newDoc.save());
      newDoc.dispose();
      files.add(outputPath);

      setState(() {
        _progress = (part + 1) / _equalParts;
      });
    }

    return files;
  }

  Future<List<String>> _splitEachPageSeparately(PdfDocument source, String path, String baseName) async {
    List<String> files = [];

    for (int i = 0; i < source.pages.count; i++) {
      final newDoc = PdfDocument();
      final template = source.pages[i].createTemplate();
      newDoc.pages.add().graphics.drawPdfTemplate(template, Offset.zero, template.size);

      final outputPath = '$path/${baseName}_Page_${i + 1}.pdf';
      final file = File(outputPath);
      await file.writeAsBytes(await newDoc.save());
      newDoc.dispose();
      files.add(outputPath);

      setState(() {
        _progress = (i + 1) / source.pages.count;
      });
    }

    return files;
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

  void _showSuccessDialog(List<String> files) {
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
              'PDF Split Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Saved to My Documents. You can find them there anytime.',
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
              child: Text(
                'Created ${files.length} PDF file${files.length > 1 ? 's' : ''}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
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
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
          'Split PDF',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          _selectedPdf == null ? _buildFileSelection() : _buildMethodSelection(),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildFileSelection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.content_cut,
              size: 60,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select a PDF to split',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickPdfFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Select PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
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

  Widget _buildMethodSelection() {
    return Column(
      children: [
        // Selected file card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
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
                      _fileName ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalPages pages • ${_formatFileSize(_fileSize)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedPdf = null;
                    _selectedMethod = null;
                  });
                },
                child: const Text('Change'),
              ),
            ],
          ),
        ),
        
        // Split methods
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Choose Split Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _buildMethodCard(
                method: SplitMethod.byPageRange,
                icon: Icons.list_alt,
                title: 'By Page Range',
                description: 'Split into custom page ranges',
              ),
              _buildMethodCard(
                method: SplitMethod.extractPages,
                icon: Icons.check_box,
                title: 'Extract Specific Pages',
                description: 'Extract selected pages as new PDF',
              ),
              _buildMethodCard(
                method: SplitMethod.everyXPages,
                icon: Icons.view_module,
                title: 'Split Every X Pages',
                description: 'Divide into equal page groups',
              ),
              _buildMethodCard(
                method: SplitMethod.equalParts,
                icon: Icons.pie_chart,
                title: 'Split into Equal Parts',
                description: 'Divide into X equal PDFs',
              ),
              _buildMethodCard(
                method: SplitMethod.eachPageSeparately,
                icon: Icons.insert_drive_file,
                title: 'Each Page Separately',
                description: 'Create separate PDF for every page',
              ),
            ],
          ),
        ),
        
        if (_selectedMethod != null) _buildActionButton(),
      ],
    );
  }

  Widget _buildMethodCard({
    required SplitMethod method,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedMethod == method;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF4CAF50) : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _splitPdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Split PDF',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
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
                Icons.content_cut,
                size: 60,
                color: Color(0xFF4CAF50),
              ),
              const SizedBox(height: 24),
              const Text(
                'Splitting PDF...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
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
