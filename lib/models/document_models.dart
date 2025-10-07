import 'dart:typed_data';

/// Supported output formats
enum DocumentFormat { pdf, jpeg }

/// Represents a single scanned page that can be previewed/selected.
class ScannedPage {
  /// Image bytes for the page preview (PNG/JPEG). Optional if [imagePath] is provided.
  final Uint8List? imageBytes;

  /// Local file path for the page preview. Optional if [imageBytes] is provided.
  final String? imagePath;

  /// Page identifier (index or external id)
  final String id;

  const ScannedPage({
    required this.id,
    this.imageBytes,
    this.imagePath,
  });
}

/// User choices from Document Setup screen
class DocumentSetupResult {
  final String fileName;
  final DocumentFormat format;
  final List<String> selectedPageIds;
  final bool mergeIntoSinglePdf;

  const DocumentSetupResult({
    required this.fileName,
    required this.format,
    required this.selectedPageIds,
    required this.mergeIntoSinglePdf,
  });
}

/// Result of persisting the document after confirmation
class SaveSuccessData {
  /// Primary saved file path. For PDF it is the single output file, for JPEG it
  /// can represent the first image path.
  final String primaryPath;

  /// All output file paths (e.g., multiple JPEGs or a single PDF)
  final List<String> allPaths;

  /// Final format
  final DocumentFormat format;

  const SaveSuccessData({
    required this.primaryPath,
    required this.allPaths,
    required this.format,
  });
}
