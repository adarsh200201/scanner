import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class DigitalSignatureScreen extends StatefulWidget {
  final String documentTitle;
  final String documentContent;

  const DigitalSignatureScreen({
    Key? key,
    required this.documentTitle,
    required this.documentContent,
  }) : super(key: key);

  @override
  State<DigitalSignatureScreen> createState() => _DigitalSignatureScreenState();
}

class _DigitalSignatureScreenState extends State<DigitalSignatureScreen> {
  List<Offset> _points = [];
  bool _hasSignature = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildDocumentPreview(),
            ),
            _buildSignatureArea(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Add Digital Signature',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _clearSignature,
            icon: const Icon(Icons.delete, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Document content
          Padding(
            padding: const EdgeInsets.all(20),
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
                  '3517 W. Gray Street, New York | +1-300-555-0399 | andrew.ainsley@yourdomain.com',
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
                  'I am writing to express my strong interest in the [insert job position] position at [insert company name]. With my background in [insert relevant qualifications and experience], I am confident that I would be a valuable addition to your team.',
                  style: TextStyle(fontSize: 10, color: Colors.black),
                ),
                const SizedBox(height: 8),
                const Text(
                  'In my previous role, I have successfully [insert relevant achievements or responsibilities]. I am particularly drawn to [insert company name] because of [insert specific reasons for interest in the company].',
                  style: TextStyle(fontSize: 10, color: Colors.black),
                ),
                const SizedBox(height: 8),
                const Text(
                  'I would welcome the opportunity to discuss how my skills and experience can contribute to your team\'s success. Thank you for considering my application.',
                  style: TextStyle(fontSize: 10, color: Colors.black),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sincerely,',
                  style: TextStyle(fontSize: 10, color: Colors.black),
                ),
                const SizedBox(height: 8),
                // Signature area
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      if (_hasSignature)
                        CustomPaint(
                          painter: SignaturePainter(_points),
                          size: const Size(double.infinity, 60),
                        ),
                      if (!_hasSignature)
                        const Center(
                          child: Text(
                            'Draw your signature or add from the library',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Andrew Ainsley',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureArea() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _points = [details.localPosition];
            _hasSignature = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _points.add(details.localPosition);
          });
        },
        onPanEnd: (details) {
          setState(() {
            _points.add(Offset.infinite);
          });
        },
        child: CustomPaint(
          painter: SignaturePainter(_points),
          size: const Size(double.infinity, 200),
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
              onPressed: _hasSignature ? _saveSignature : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasSignature ? Colors.blue : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continue',
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

  void _clearSignature() {
    setState(() {
      _points = [];
      _hasSignature = false;
    });
  }

  void _saveSignature() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Digital signature added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
