import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'document_editor.dart';

enum ScanMode {
  qrCode,
  book,
  idCard,
  businessCard,
  document,
}

class ScanScreen extends StatefulWidget {
  final ScanMode initialMode;
  
  const ScanScreen({
    Key? key,
    this.initialMode = ScanMode.qrCode,
  }) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  ScanMode _currentMode = ScanMode.qrCode;
  bool _flashOn = false;
  dynamic _scanResult;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
  }

  Future<void> _startScanning() async {
    // Use real camera capture to ensure we have an actual image path
    await _captureWithCamera();
  }

  void _showScanResult(dynamic result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getModeTitle()} Result'),
        content: Text(result.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getModeTitle() {
    switch (_currentMode) {
      case ScanMode.qrCode:
        return 'QR Code';
      case ScanMode.book:
        return 'Book';
      case ScanMode.idCard:
        return 'ID Card';
      case ScanMode.businessCard:
        return 'Business Card';
      case ScanMode.document:
        return 'Document';
    }
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
              child: _buildScanningArea(),
            ),
            _buildBottomControls(),
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
              'Scan ${_getModeTitle()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.crop_free, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.auto_fix_high, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _flashOn = !_flashOn;
              });
            },
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningArea() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: _overlayForCurrentMode(),
        ),
      ),
    );
  }



  // Build scanning guide with instructions (NO dummy images)
  Widget _buildScanGuide(String instruction, {double width = 300, double height = 200}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Scanning frame
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomPaint(
            painter: DashedLinePainter(),
          ),
        ),
        const SizedBox(height: 30),
        // Instructions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _overlayForCurrentMode() {
    switch (_currentMode) {
      case ScanMode.qrCode:
        return _buildQRCodeOverlay();
      case ScanMode.book:
        return _buildBookOverlay();
      case ScanMode.idCard:
        return _buildIDCardOverlay();
      case ScanMode.businessCard:
        return _buildBusinessCardOverlay();
      case ScanMode.document:
        return _buildDocumentOverlay();
    }
  }

  Widget _buildQRCodeOverlay() {
    return _buildScanGuide(
      'Position the QR code within the frame.\nKeep your device steady for accurate scanning.',
      width: 250,
      height: 250,
    );
  }

  Widget _buildBookOverlay() {
    return _buildScanGuide(
      'Place the open book pages fully within the frame.\nMake sure the text is clear and flat, so we can capture every word accurately.',
      width: 320,
      height: 220,
    );
  }

  Widget _buildBookOverlay_OLD() {
    return Stack(
      children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
        ),
        // Book mockup
        Center(
          child: Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.green[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'CHAPTER VI\nGERAULT, THE BOX OF ERBIS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        // Dashed line guide
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: CustomPaint(
            painter: DashedLinePainter(),
          ),
        ),
        // Page numbers
        Positioned(
          left: 50,
          top: 100,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                '1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 50,
          top: 100,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                '2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIDCardOverlay() {
    return _buildScanGuide(
      'Align your ID card within the blue border.\nEnsure the card is fully visible and the details are not blurred for precise extraction.',
      width: 320,
      height: 200,
    );
  }

  Widget _buildIDCardOverlay_OLD() {
    return Stack(
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/wood_texture.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // ID Card mockup
        Center(
          child: Container(
            width: 280,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.blue[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Stack(
              children: [
                // Corner handles
                ...List.generate(8, (index) {
                  bool isCorner = index < 4;
                  return Positioned(
                    top: isCorner ? (index < 2 ? 0 : null) : 50,
                    bottom: isCorner ? (index >= 2 ? 0 : null) : 50,
                    left: isCorner ? (index % 2 == 0 ? 0 : null) : 0,
                    right: isCorner ? (index % 2 == 1 ? 0 : null) : 0,
                    child: Container(
                      width: isCorner ? 20 : 15,
                      height: isCorner ? 20 : 15,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isCorner ? 10 : 4),
                      ),
                    ),
                  );
                }),
                // ID Card content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IDENTIFICATION CARD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildIDField('Name', 'Andrew Ainsley'),
                                _buildIDField('ID No.', '573813659'),
                                _buildIDField('Country', 'United States'),
                                _buildIDField('Issued', 'Dec 2023'),
                                _buildIDField('Expires', 'Nov 2026'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessCardOverlay() {
    return _buildScanGuide(
      'Place your business card within the frame.\nEnsure all text and contact details are clearly visible for accurate scanning.',
      width: 320,
      height: 200,
    );
  }

  Widget _buildBusinessCardOverlay_OLD() {
    return Stack(
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/wood_texture.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Business Card mockup
        Center(
          child: Container(
            width: 300,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Stack(
              children: [
                // Corner handles
                ...List.generate(4, (index) {
                  return Positioned(
                    top: index < 2 ? 0 : null,
                    bottom: index >= 2 ? 0 : null,
                    left: index % 2 == 0 ? 0 : null,
                    right: index % 2 == 1 ? 0 : null,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                    ),
                  );
                }),
                // Business Card content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Andrew Ainsley'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.phone, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('+1-300-555-0399'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.email, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('andrew@example.com'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apple, color: Colors.white, size: 30),
                            Text(
                              'Apple Inc.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentOverlay() {
    return _buildScanGuide(
      'Position your document within the frame.\nMake sure the entire document is visible and the text is clear for best results.',
      width: 300,
      height: 400,
    );
  }

  Widget _buildDocumentOverlay_OLD() {
    return Stack(
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/wood_texture.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Document mockup
        Center(
          child: Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Stack(
              children: [
                // Corner handles
                ...List.generate(4, (index) {
                  return Positioned(
                    top: index < 2 ? 0 : null,
                    bottom: index >= 2 ? 0 : null,
                    left: index % 2 == 0 ? 0 : null,
                    right: index % 2 == 1 ? 0 : null,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
                // Side handles
                ...List.generate(4, (index) {
                  return Positioned(
                    top: index == 0 ? 0 : null,
                    bottom: index == 1 ? 0 : null,
                    left: index == 2 ? 0 : null,
                    right: index == 3 ? 0 : null,
                    child: Container(
                      width: index < 2 ? 20 : 15,
                      height: index < 2 ? 15 : 20,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
                // Document content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Andrew Ainsley',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '3517 W. Gray Street, New York',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Text(
                        '+1-300-555-0399 | andrew.ainsley@yourdomain.com',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'December 30, 2023',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Google Inc.\n1600 Amphitheatre Parkway\nMountain View, CA 94043',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Dear Hiring Manager,',
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'I am writing to express my strong interest in the [insert job position] position...',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIDField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.grey),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Mode selector
          Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildModeButton('Book', ScanMode.book),
                _buildModeButton('ID Card', ScanMode.idCard),
                _buildModeButton('Document', ScanMode.document),
                _buildModeButton('Business Card', ScanMode.businessCard),
                _buildModeButton('QR Code', ScanMode.qrCode),
              ],
            ),
          ),
          // Control buttons
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _toggleFlash,
                  child: _buildControlButton(
                    _flashOn ? Icons.flash_on : Icons.flash_off,
                    _flashOn ? Colors.yellow[700]! : Colors.grey[800]!,
                  ),
                ),
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: _buildControlButton(Icons.photo_library, Colors.grey[800]!),
                ),
                _buildCaptureButton(),
                GestureDetector(
                  onTap: _startScanning,
                  child: _buildControlButton(Icons.document_scanner, Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String title, ScanMode mode) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
                  bottom: BorderSide(color: Colors.blue, width: 2),
                )
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  // Toggle flash
  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
    });
    _showSnackBar(_flashOn ? 'Flash On' : 'Flash Off');
  }

  // Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null && mounted) {
        // Navigate to document editor with the selected image
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentEditor(
              documentTitle: 'Scanned Document',
              documentContent: '',
              filePath: image.path,
              fileType: 'Image',
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  // Show snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _captureWithCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentEditor(
              documentTitle: 'Scanned Document',
              documentContent: '',
              filePath: photo.path,
              fileType: 'Image',
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Camera failed: $e');
    }
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _captureWithCamera,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 3),
        ),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isScanning ? Colors.blue : Colors.grey[800],
          ),
          child: _isScanning
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 30,
                ),
        ),
      ),
    );
  }

  String _getInstructions() {
    switch (_currentMode) {
      case ScanMode.qrCode:
        return 'Please point the camera at the QR Code';
      case ScanMode.book:
        return 'Position the book within the frame';
      case ScanMode.idCard:
        return 'Align the ID card within the frame';
      case ScanMode.businessCard:
        return 'Position the business card within the frame';
      case ScanMode.document:
        return 'Position the document within the frame';
    }
  }

  String _getSampleDocumentContent() {
    return '''Andrew Ainsley
3517 W. Gray Street, New York | +1-300-555-0399 | andrew.ainsley@yourdomain.com

December 30, 2023

Google Inc.
1600 Amphitheatre Parkway
Mountain View, CA 94043

Dear Hiring Manager,

I am writing to express my strong interest in the [insert job position] position at [insert company name]. With my background in [insert relevant qualifications and experience], I am confident that I would be a valuable addition to your team.

In my previous role, I have successfully [insert relevant achievements or responsibilities]. I am particularly drawn to [insert company name] because of [insert specific reasons for interest in the company].

I would welcome the opportunity to discuss how my skills and experience can contribute to your team's success. Thank you for considering my application.

Sincerely,
Andrew Ainsley''';
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height);

    canvas.drawPath(
      path,
      paint..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
