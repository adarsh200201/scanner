import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/share_actions.dart';
import 'document_viewer.dart';

class SaveSuccessScreen extends StatelessWidget {
  final String title;
  final String? filePath;
  final List<String>? imagePaths;
  final String successMessage;

  const SaveSuccessScreen({
    Key? key,
    required this.title,
    required this.filePath,
    this.imagePaths,
    this.successMessage = 'Converted to JPEG Successfully!',
  }) : super(key: key);

  bool get _isImage =>
      (filePath ?? '').toLowerCase().endsWith('.jpg') ||
      (filePath ?? '').toLowerCase().endsWith('.jpeg') ||
      (filePath ?? '').toLowerCase().endsWith('.png');

  bool get _isPdf => (filePath ?? '').toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    final previewPath = _pickPreviewPath();

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B7FFF).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5B7FFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            successMessage,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (previewPath != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _resolveFile(previewPath),
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        width: 160,
                        height: 160,
                        color: Colors.grey[200],
                        child: const Icon(Icons.insert_drive_file, size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _primaryButton(
                        label: 'SHARE',
                        onTap: () => ShareActions.sharePaths(
                          context,
                          title,
                          (imagePaths != null && imagePaths!.isNotEmpty)
                              ? imagePaths!
                              : (filePath != null ? [filePath!] : <String>[]),
                        ),
                        filled: true,
                      ),
                      const SizedBox(height: 12),
                      _primaryButton(
                        label: 'OPEN',
                        onTap: () => ShareActions.openViewer(
                          context,
                          title,
                          filePath: filePath,
                          imagePaths: imagePaths,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isPdf)
                        _primaryButton(
                          label: 'DOWNLOAD PDF',
                          onTap: () => ShareActions.openViewer(
                            context,
                            title,
                            filePath: filePath,
                          ),
                        )
                      else
                        _primaryButton(
                          label: 'SAVE TO GALLERY',
                          onTap: _isImage
                              ? () => ShareActions.saveImagesToGallery(
                                    context,
                                    title,
                                    (imagePaths != null && imagePaths!.isNotEmpty)
                                        ? imagePaths!
                                        : (filePath != null ? [filePath!] : <String>[]),
                                  )
                              : null,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _pickPreviewPath() {
    if (imagePaths != null && imagePaths!.isNotEmpty) return imagePaths!.first;
    if (filePath != null && filePath!.isNotEmpty) return filePath!;
    return null;
  }


  File _resolveFile(String path) => path.startsWith('file://')
      ? File.fromUri(Uri.parse(path))
      : File(path);

  Widget _primaryButton({required String label, required VoidCallback? onTap, bool filled = false}) {
    final borderColor = const Color(0xFF5B7FFF);
    final textColor = filled ? Colors.white : borderColor;
    final bgColor = filled ? borderColor : Colors.transparent;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: onTap == null ? Colors.grey : textColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
