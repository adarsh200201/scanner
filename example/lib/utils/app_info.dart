import 'package:flutter/material.dart';

class AppInfo {
  static const String appName = 'ProScan';
  static const String appVersion = '1.0.0';

  static const String developerName = 'Adarsh Sharma';
  static const String organization = 'ProScan Labs';
  static const String websiteUrl = 'https://github.com/adarsh200201/scanner';
  static const String supportEmail = 'work.devoff@gmail.com';

  static const String description =
      'ProScan is a professional document scanner that helps you capture, enhance, and export documents as PDF/JPEG. It offers OCR, PDF tools (merge, split, protect), and easy sharing to streamline your workflow.';

  static const String releaseNotes =
      'Initial release with document scanning, OCR, PDF merge/split, password protection, file management, and quick sharing.';

  static const List<AckItem> acknowledgments = [
    AckItem('flutter_doc_scanner', 'Core scanning plugin'),
    AckItem('syncfusion_flutter_pdf', 'PDF operations'),
    AckItem('google_mlkit_text_recognition', 'OCR text recognition'),
    AckItem('camera', 'Camera access'),
    AckItem('image_picker', 'Pick images from gallery'),
    AckItem('pdf', 'Create PDFs from images'),
    AckItem('printing', 'Print & preview PDFs'),
    AckItem('share_plus', 'Share documents'),
    AckItem('url_launcher', 'Open links and emails'),
  ];
}

class AckItem {
  final String name;
  final String purpose;
  const AckItem(this.name, this.purpose);
}

extension AckTheme on BuildContext {
  Color get primaryBlue => const Color(0xFF5B7FFF);
}
