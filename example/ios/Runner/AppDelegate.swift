import UIKit
import Flutter
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "proscan.gallery", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "saveImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
        result(FlutterError(code: "ARG", message: "Missing path", details: nil))
        return
      }
      let title = args["title"] as? String
      self?.saveImageToGallery(path: path, title: title, result: result)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveImageToGallery(path: String, title: String?, result: @escaping FlutterResult) {
    let resolvedPath: String
    if path.hasPrefix("file://") {
      resolvedPath = URL(string: path)?.path ?? path
    } else {
      resolvedPath = path
    }

    guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: resolvedPath)), let image = UIImage(data: imageData) else {
      result(false)
      return
    }

    let saveBlock = {
      PHPhotoLibrary.shared().performChanges({
        PHAssetCreationRequest.creationRequestForAsset(from: image)
      }) { success, error in
        if let error = error {
          result(FlutterError(code: "ERR", message: error.localizedDescription, details: nil))
        } else {
          result(success)
        }
      }
    }

    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        DispatchQueue.main.async {
          guard status == .authorized || status == .limited else {
            result(FlutterError(code: "PERM", message: "Photo library add permission denied", details: nil))
            return
          }
          saveBlock()
        }
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        DispatchQueue.main.async {
          guard status == .authorized else {
            result(FlutterError(code: "PERM", message: "Photo library permission denied", details: nil))
            return
          }
          saveBlock()
        }
      }
    }
  }
}
