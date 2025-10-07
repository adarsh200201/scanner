import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfService {
  /// Convert images to PDF
  static Future<String?> convertImagesToPdf({
    required List<String> imagePaths,
    required String fileName,
    String quality = 'Regular',
  }) async {
    try {
      if (imagePaths.isEmpty) {
        print('No images to convert to PDF');
        return null;
      }

      final doc = pw.Document();

      // Determine quality settings
      int imageQuality;
      switch (quality) {
        case 'Low':
          imageQuality = 50;
          break;
        case 'Medium':
          imageQuality = 70;
          break;
        case 'Regular':
          imageQuality = 85;
          break;
        case 'Max':
          imageQuality = 100;
          break;
        default:
          imageQuality = 85;
      }

      // Add each image as a page with native size and no margins/background
      for (String imagePath in imagePaths) {
        final imageFile = imagePath.startsWith('file://')
            ? File.fromUri(Uri.parse(imagePath))
            : File(imagePath);

        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();

          // Decode size using PdfImage to size page exactly like the scan
          final pdfImage = PdfImage.file(
            doc.document,
            bytes: imageBytes,
          );

          final pageFormat = PdfPageFormat(
            pdfImage.width.toDouble(),
            pdfImage.height.toDouble(),
          );

          doc.addPage(
            pw.Page(
              pageTheme: pw.PageTheme(
                pageFormat: pageFormat,
                margin: pw.EdgeInsets.zero,
                theme: pw.ThemeData(defaultTextStyle: const pw.TextStyle(color: PdfColors.black)),
              ),
              build: (pw.Context context) {
                // Draw the image to fill the page fully, no background added
                return pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.fill);
              },
            ),
          );
        } else {
          print('Image file does not exist: $imagePath');
        }
      }

      // Save PDF to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final pdfPath = '${directory.path}/$fileName.pdf';
      final file = File(pdfPath);
      
      await file.writeAsBytes(await doc.save());

      print('PDF created successfully at: $pdfPath');
      return pdfPath;
    } catch (e) {
      print('Error converting images to PDF: $e');
      return null;
    }
  }

  /// Convert images to PDF and write to a specific output file path
  static Future<String?> convertImagesToPdfAtPath({
    required List<String> imagePaths,
    required String outputPath,
    String quality = 'Regular',
  }) async {
    try {
      if (imagePaths.isEmpty) {
        return null;
      }
      final doc = pw.Document();

      int imageQuality;
      switch (quality) {
        case 'Low':
          imageQuality = 50;
          break;
        case 'Medium':
          imageQuality = 70;
          break;
        case 'Regular':
          imageQuality = 85;
          break;
        case 'Max':
          imageQuality = 100;
          break;
        default:
          imageQuality = 85;
      }

      for (final path in imagePaths) {
        final file = path.startsWith('file://') ? File.fromUri(Uri.parse(path)) : File(path);
        if (!await file.exists()) continue;
        final imageBytes = await file.readAsBytes();
        final pdfImage = PdfImage.file(doc.document, bytes: imageBytes);
        final pageFormat = PdfPageFormat(pdfImage.width.toDouble(), pdfImage.height.toDouble());
        doc.addPage(
          pw.Page(
            pageTheme: pw.PageTheme(
              pageFormat: pageFormat,
              margin: pw.EdgeInsets.zero,
              theme: pw.ThemeData(defaultTextStyle: const pw.TextStyle(color: PdfColors.black)),
            ),
            build: (_) => pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.fill),
          ),
        );
      }

      final outFile = File(outputPath);
      await outFile.writeAsBytes(await doc.save());
      return outFile.path;
    } catch (_) {
      return null;
    }
  }

  /// Get PDF file size
  static Future<int> getPdfSize(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Error getting PDF size: $e');
      return 0;
    }
  }
}
