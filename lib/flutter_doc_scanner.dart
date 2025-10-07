import 'package:flutter/foundation.dart';
import 'flutter_doc_scanner_platform_interface.dart';

// UI pages and models to help apps build a complete scanning flow
export 'models/document_models.dart';
export 'ui/document_setup_page.dart';
export 'ui/save_success_page.dart';
export 'ui/flow.dart';

// Local storage exports
export 'models/scanned_doc.dart';
export 'repositories/storage_repository.dart';

class FlutterDocScanner {
  Future<String?> getPlatformVersion() {
    return FlutterDocScannerPlatform.instance.getPlatformVersion();
  }

  Future<dynamic> getScanDocuments({int page = 4}) {
    return FlutterDocScannerPlatform.instance.getScanDocuments(page);
  }

  Future<dynamic> getScannedDocumentAsImages({int page = 4}) {
    return FlutterDocScannerPlatform.instance.getScannedDocumentAsImages(page);
  }

  Future<dynamic> getScannedDocumentAsPdf({int page = 4}) {
    return FlutterDocScannerPlatform.instance.getScannedDocumentAsPdf(page);
  }

  Future<dynamic> getScanDocumentsUri({int page = 4}) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return FlutterDocScannerPlatform.instance.getScanDocumentsUri(page);
    } else {
      return Future.error(
          "Currently, this feature is supported only on Android Platform");
    }
  }
}
