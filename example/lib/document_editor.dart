import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'scan_screen.dart';

class DocumentEditor extends StatefulWidget {
  final String documentTitle;
  final String documentContent;
  final String? filePath;
  final String? fileType;
  
  const DocumentEditor({
    Key? key,
    required this.documentTitle,
    required this.documentContent,
    this.filePath,
    this.fileType,
  }) : super(key: key);

  @override
  State<DocumentEditor> createState() => _DocumentEditorState();
}

class _DocumentEditorState extends State<DocumentEditor> {
  String _editedContent = '';
  bool _isEditing = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editedContent = widget.documentContent;
    _textController.text = _editedContent;
    print('DocumentEditor - Title: ${widget.documentTitle}');
    print('DocumentEditor - Content: ${widget.documentContent}');
    print('DocumentEditor - FilePath: ${widget.filePath}');
    print('DocumentEditor - FileType: ${widget.fileType}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _buildDocumentArea(),
            ),
            _buildEditingTools(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              widget.documentTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: _isEditing ? _saveDocument : _startEditing,
            child: Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _isEditing ? _buildEditingArea() : _buildDocumentPreview(),
    );
  }

  Widget _buildDocumentPreview() {
    // Check if we have an actual image file to display
    if (widget.filePath != null && 
        (widget.filePath!.endsWith('.jpg') || 
         widget.filePath!.endsWith('.jpeg') || 
         widget.filePath!.endsWith('.png'))) {
      return _buildImagePreview();
    }
    
    // Otherwise show text content or no content message
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.documentTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.fileType ?? 'Document',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content or no image message
          if (widget.filePath == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.image_not_supported, color: Colors.grey[400], size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'No image available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This document was created without an image scan',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Text(
              _editedContent,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Document info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.documentTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Scanned Document',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Image display
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: File(widget.filePath!).existsSync()
                ? Image.file(
                    File(widget.filePath!),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.grey[400], size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'Unable to load image',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, color: Colors.grey[400], size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'File not found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // Document content if available
          if (_editedContent.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _editedContent,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditingArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _textController,
        maxLines: null,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Edit document content...',
        ),
        onChanged: (value) {
          setState(() {
            _editedContent = value;
          });
        },
      ),
    );
  }

  Widget _buildEditingTools() {
    return Container(
      height: 80,
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(Icons.refresh, 'Retake', () => _retakeDocument()),
          _buildToolButton(Icons.crop, 'Crop', () => _cropDocument()),
          _buildToolButton(Icons.rotate_right, 'Rotate', () => _rotateDocument()),
          _buildToolButton(Icons.auto_fix_high, 'Filter', () => _applyFilter()),
          _buildToolButton(Icons.aspect_ratio, 'Resize', () => _resizeDocument()),
          _buildToolButton(Icons.delete, 'Delete', () => _deleteDocument()),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _scanMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Scan More',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _savePDF,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveDocument() {
    setState(() {
      _isEditing = false;
    });
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document saved successfully!')),
    );
  }

  void _retakeDocument() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retake Document'),
        content: const Text('This will discard current changes and start a new scan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Retake'),
          ),
        ],
      ),
    );
  }

  void _cropDocument() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropScreen(
          documentTitle: widget.documentTitle,
          documentContent: _editedContent,
        ),
      ),
    );
  }

  void _rotateDocument() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document rotated 90°')),
    );
  }

  void _applyFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Auto', true),
            _buildFilterOption('Black & White', false),
            _buildFilterOption('Grayscale', false),
            _buildFilterOption('Color', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter applied!')),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String name, bool isSelected) {
    return ListTile(
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name filter applied!')),
        );
      },
    );
  }

  void _resizeDocument() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResizeScreen(
          documentTitle: widget.documentTitle,
          documentContent: _editedContent,
        ),
      ),
    );
  }

  void _deleteDocument() {
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
            const Text('Are you sure you want to delete this document?', style: TextStyle(color: Colors.black54)),
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
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Document deleted')),
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

  void _scanMore() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanScreen(initialMode: ScanMode.document),
      ),
    );
  }

  void _savePDF() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save PDF'),
        content: const Text('Document saved as PDF successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class CropScreen extends StatefulWidget {
  final String documentTitle;
  final String documentContent;

  const CropScreen({
    Key? key,
    required this.documentTitle,
    required this.documentContent,
  }) : super(key: key);

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _buildCropArea(),
            ),
            _buildCropControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Crop Document',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCropArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Document preview
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Document Preview\nwith Crop Handles',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          // Crop handles
          ...List.generate(8, (index) {
            bool isCorner = index < 4;
            return Positioned(
              top: isCorner ? (index < 2 ? 20 : null) : 100,
              bottom: isCorner ? (index >= 2 ? 20 : null) : 100,
              left: isCorner ? (index % 2 == 0 ? 20 : null) : 0,
              right: isCorner ? (index % 2 == 1 ? 20 : null) : 0,
              child: Container(
                width: isCorner ? 20 : 15,
                height: isCorner ? 20 : 15,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(isCorner ? 10 : 4),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCropControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document cropped successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Apply Crop',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResizeScreen extends StatefulWidget {
  final String documentTitle;
  final String documentContent;

  const ResizeScreen({
    Key? key,
    required this.documentTitle,
    required this.documentContent,
  }) : super(key: key);

  @override
  State<ResizeScreen> createState() => _ResizeScreenState();
}

class _ResizeScreenState extends State<ResizeScreen> {
  String _selectedSize = 'Auto Fit';

  final List<ResizeOption> _resizeOptions = [
    ResizeOption('Auto Fit', true),
    ResizeOption('A4 Portrait', false),
    ResizeOption('A3 Portrait', false),
    ResizeOption('A5 Portrait', false),
    ResizeOption('US Letter Portrait', false),
    ResizeOption('US Portrait', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _buildResizeArea(),
            ),
            _buildResizeOptions(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Resize',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildResizeArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Document Preview\nResize Preview',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildResizeOptions() {
    return Container(
      height: 120,
      color: Colors.grey[900],
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Document Size',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _resizeOptions.length,
              itemBuilder: (context, index) {
                final option = _resizeOptions[index];
                return _buildResizeOption(option);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResizeOption(ResizeOption option) {
    final isSelected = _selectedSize == option.name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSize = option.name;
        });
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              option.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Document resized to $_selectedSize')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResizeOption {
  final String name;
  final bool isDefault;

  ResizeOption(this.name, this.isDefault);
}
