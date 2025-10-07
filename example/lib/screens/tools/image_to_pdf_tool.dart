import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../services/storage_service.dart';
import '../document_viewer.dart';
import 'package:image/image.dart' as img;

class ImageToPdfTool extends StatefulWidget {
  const ImageToPdfTool({Key? key}) : super(key: key);

  @override
  State<ImageToPdfTool> createState() => _ImageToPdfToolState();
}

class _ImageToPdfToolState extends State<ImageToPdfTool> {
  final ImagePicker _picker = ImagePicker();
  List<ImageItem> _selectedImages = [];
  bool _isProcessing = false;
  double _progress = 0.0;
  String _outputFileName = '';
  
  // PDF Settings
  PdfPageFormat _pageSize = PdfPageFormat.a4;
  bool _isPortrait = true;
  String _fitMode = 'fit'; // fit, fill, actual, stretch
  double _margin = 10.0;
  String _quality = 'high';

  @override
  void initState() {
    super.initState();
    _generateDefaultFileName();
  }

  void _generateDefaultFileName() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    _outputFileName = 'Images_to_PDF_${formatter.format(now)}';
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      for (var image in images) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        final decodedImage = img.decodeImage(bytes);
        
        if (decodedImage != null) {
          setState(() {
            _selectedImages.add(ImageItem(
              file: file,
              name: image.name,
              width: decodedImage.width,
              height: decodedImage.height,
            ));
          });
        }
      }
    } catch (e) {
      _showError('Error picking images: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      
      if (photo != null) {
        final file = File(photo.path);
        final bytes = await file.readAsBytes();
        final decodedImage = img.decodeImage(bytes);
        
        if (decodedImage != null) {
          setState(() {
            _selectedImages.add(ImageItem(
              file: file,
              name: photo.name,
              width: decodedImage.width,
              height: decodedImage.height,
            ));
          });
        }
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    }
  }

  Future<void> _createPdf() async {
    if (_selectedImages.isEmpty) {
      _showError('Please select at least one image');
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
    });

    try {
      final pdf = pw.Document();
      
      for (int i = 0; i < _selectedImages.length; i++) {
        final imageBytes = await _selectedImages[i].file.readAsBytes();
        final image = pw.MemoryImage(imageBytes);
        
        // Apply page orientation
        final pageFormat = _isPortrait ? _pageSize : _pageSize.landscape;
        
        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.all(_margin),
            build: (pw.Context context) {
              return pw.Center(
                child: _buildImageWidget(image),
              );
            },
          ),
        );
        
        setState(() {
          _progress = (i + 1) / _selectedImages.length;
        });
      }

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/$_outputFileName.pdf';
      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());
      final size = await file.length();

      await StorageService.addExternalFile(name: _outputFileName, filePath: outputPath, fileSize: size, type: 'document');

      setState(() {
        _isProcessing = false;
      });

      _showSuccessDialog(outputPath, size);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Error creating PDF: $e');
    }
  }

  pw.Widget _buildImageWidget(pw.MemoryImage image) {
    switch (_fitMode) {
      case 'fill':
        return pw.Image(image, fit: pw.BoxFit.cover);
      case 'actual':
        return pw.Image(image, fit: pw.BoxFit.none);
      case 'stretch':
        return pw.Image(image, fit: pw.BoxFit.fill);
      default: // 'fit'
        return pw.Image(image, fit: pw.BoxFit.contain);
    }
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
              'PDF Created Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                  Text('Pages: ${_selectedImages.length}'),
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
                        _selectedImages.clear();
                        _generateDefaultFileName();
                      });
                    },
                    child: const Text('Create Another'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => DocumentViewer(documentTitle: _outputFileName, filePath: filePath),
                      ));
                    },
                    child: const Text('Open'),
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
                      backgroundColor: const Color(0xFFFF9800),
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

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PDF Settings',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              
              // Page Size
              const Text('Page Size', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('A4'),
                    selected: _pageSize == PdfPageFormat.a4,
                    onSelected: (selected) {
                      setModalState(() => _pageSize = PdfPageFormat.a4);
                      setState(() => _pageSize = PdfPageFormat.a4);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Letter'),
                    selected: _pageSize == PdfPageFormat.letter,
                    onSelected: (selected) {
                      setModalState(() => _pageSize = PdfPageFormat.letter);
                      setState(() => _pageSize = PdfPageFormat.letter);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Legal'),
                    selected: _pageSize == PdfPageFormat.legal,
                    onSelected: (selected) {
                      setModalState(() => _pageSize = PdfPageFormat.legal);
                      setState(() => _pageSize = PdfPageFormat.legal);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Orientation
              const Text('Orientation', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.portrait, size: 20),
                          SizedBox(width: 4),
                          Text('Portrait'),
                        ],
                      ),
                      selected: _isPortrait,
                      onSelected: (selected) {
                        setModalState(() => _isPortrait = true);
                        setState(() => _isPortrait = true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.landscape, size: 20),
                          SizedBox(width: 4),
                          Text('Landscape'),
                        ],
                      ),
                      selected: !_isPortrait,
                      onSelected: (selected) {
                        setModalState(() => _isPortrait = false);
                        setState(() => _isPortrait = false);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Fit Mode
              const Text('Image Fit Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Fit to Page'),
                    selected: _fitMode == 'fit',
                    onSelected: (selected) {
                      setModalState(() => _fitMode = 'fit');
                      setState(() => _fitMode = 'fit');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Fill Page'),
                    selected: _fitMode == 'fill',
                    onSelected: (selected) {
                      setModalState(() => _fitMode = 'fill');
                      setState(() => _fitMode = 'fill');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Actual Size'),
                    selected: _fitMode == 'actual',
                    onSelected: (selected) {
                      setModalState(() => _fitMode = 'actual');
                      setState(() => _fitMode = 'actual');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Margin
              Text('Margins: ${_margin.toInt()} mm', style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: _margin,
                min: 0,
                max: 50,
                divisions: 10,
                label: '${_margin.toInt()} mm',
                onChanged: (value) {
                  setModalState(() => _margin = value);
                  setState(() => _margin = value);
                },
              ),
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Apply Settings'),
                ),
              ),
            ],
          ),
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
          'Image to PDF',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_selectedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: _showSettingsSheet,
            ),
        ],
      ),
      body: Stack(
        children: [
          _selectedImages.isEmpty ? _buildImageSelection() : _buildImageGrid(),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildImageSelection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0CC),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.image,
              size: 60,
              color: Color(0xFFFF9800),
            ),
          ),
          const SizedBox(height: 32),
          
          // Camera Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt, size: 32),
              label: const Text('Take Photo', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Gallery Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton.icon(
              onPressed: _pickImagesFromGallery,
              icon: const Icon(Icons.photo_library, size: 32),
              label: const Text('Choose from Gallery', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Column(
      children: [
        // Image count header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedImages.length} image${_selectedImages.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _pickImagesFromGallery,
              ),
            ],
          ),
        ),
        
        // Image grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImages[index].file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        
        // Bottom action bar
        Container(
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
                TextField(
                  decoration: InputDecoration(
                    labelText: 'PDF Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixText: '.pdf',
                  ),
                  controller: TextEditingController(text: _outputFileName),
                  onChanged: (value) => _outputFileName = value,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create PDF',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                Icons.picture_as_pdf,
                size: 60,
                color: Color(0xFFFF9800),
              ),
              const SizedBox(height: 24),
              const Text(
                'Creating PDF...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
              ),
              const SizedBox(height: 8),
              Text(
                'Processing image ${(_progress * _selectedImages.length).ceil()} of ${_selectedImages.length}',
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

class ImageItem {
  final File file;
  final String name;
  final int width;
  final int height;

  ImageItem({
    required this.file,
    required this.name,
    required this.width,
    required this.height,
  });
}
