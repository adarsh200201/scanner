import 'package:flutter/material.dart';
import '../models/document_models.dart';
import 'document_setup_page.dart';
import 'save_success_page.dart';

/// Shows the Document Setup page, then Success page after saving.
///
/// - [imageUris] should be file:// or plain paths to scanned images.
/// - [onConfirm] must persist files (build PDF or copy JPEGs) and return
///   [SaveSuccessData]. This keeps the library free of extra dependencies.
Future<SaveSuccessData?> showDocumentSetupFlow(
  BuildContext context, {
  required String initialFileName,
  required List<String> imageUris,
  required Future<SaveSuccessData> Function(DocumentSetupResult result) onConfirm,
  Future<void> Function(SaveSuccessData data)? onShare,
  Future<void> Function(SaveSuccessData data)? onOpen,
  Future<void> Function(SaveSuccessData data)? onSaveToGallery,
}) async {
  final pages = <ScannedPage>[];
  for (var i = 0; i < imageUris.length; i++) {
    final uri = Uri.parse(imageUris[i]);
    final path = uri.scheme.isEmpty ? imageUris[i] : uri.path;
    pages.add(ScannedPage(id: '$i', imagePath: path));
  }

  SaveSuccessData? saved;

  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => DocumentSetupPage(
      initialFileName: initialFileName,
      pages: pages,
      onConfirm: (setup) async {
        final result = await onConfirm(setup);
        saved = result;
        if (context.mounted) {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SaveSuccessPage(
              data: result,
              onShare: () async => onShare == null ? Future.value() : onShare(result),
              onOpen: () async => onOpen == null ? Future.value() : onOpen(result),
              onSaveToGallery: () async => onSaveToGallery == null ? Future.value() : onSaveToGallery(result),
              onBackToHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ));
        }
        return result;
      },
    ),
  ));

  return saved;
}
