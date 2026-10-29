import Flutter
import PhotosUI
import UIKit
import Vision
import VisionKit

/// Receipt scanning for `ReceiptScannerService` (Dart), on the device:
///
/// - `capabilities` → `{camera: Bool}` (the simulator has no document camera)
/// - `capture {source: "camera" | "photos"}` → path of a temporary JPEG, or
///   nil when the user backs out. VisionKit's document camera finds the
///   edges and straightens the page; the photo picker needs no permission.
/// - `recognize {path}` → `[{text, left, top, right, bottom}]`, one entry
///   per recognised line, boxes normalised with the origin top-left.
final class ReceiptScannerPlugin: NSObject, FlutterPlugin,
  VNDocumentCameraViewControllerDelegate, PHPickerViewControllerDelegate
{
  private var pending: FlutterResult?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "business_ledger/receipt_scanner",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(ReceiptScannerPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    switch call.method {
    case "capabilities":
      result(["camera": VNDocumentCameraViewController.isSupported])
    case "capture":
      capture(source: arguments?["source"] as? String, result: result)
    case "recognize":
      guard let path = arguments?["path"] as? String else {
        result(FlutterError(code: "bad-args", message: "path is required", details: nil))
        return
      }
      recognize(path: path, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Capture

  private func capture(source: String?, result: @escaping FlutterResult) {
    guard pending == nil else {
      result(FlutterError(code: "busy", message: "A scan is already open.", details: nil))
      return
    }
    guard let presenter = Self.topViewController() else {
      result(FlutterError(code: "no-ui", message: "Nothing to present on.", details: nil))
      return
    }
    if source == "camera" {
      guard VNDocumentCameraViewController.isSupported else {
        result(FlutterError(code: "unavailable", message: "No document camera.", details: nil))
        return
      }
      pending = result
      let camera = VNDocumentCameraViewController()
      camera.delegate = self
      presenter.present(camera, animated: true)
    } else {
      pending = result
      var configuration = PHPickerConfiguration()
      configuration.filter = .images
      configuration.selectionLimit = 1
      let picker = PHPickerViewController(configuration: configuration)
      picker.delegate = self
      presenter.present(picker, animated: true)
    }
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController,
    didFinishWith scan: VNDocumentCameraScan
  ) {
    let image = scan.pageCount > 0 ? scan.imageOfPage(at: 0) : nil
    controller.dismiss(animated: true) { self.save(image) }
  }

  func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    controller.dismiss(animated: true) { self.finish(nil) }
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController,
    didFailWithError error: Error
  ) {
    controller.dismiss(animated: true) {
      self.fail("capture-failed", error.localizedDescription)
    }
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard let provider = results.first?.itemProvider,
      provider.canLoadObject(ofClass: UIImage.self)
    else {
      finish(nil)
      return
    }
    provider.loadObject(ofClass: UIImage.self) { object, error in
      DispatchQueue.main.async {
        if let image = object as? UIImage {
          self.save(image)
        } else {
          self.fail("capture-failed", error?.localizedDescription ?? "Unreadable image.")
        }
      }
    }
  }

  /// Writes [image] to a temporary JPEG (the Dart side deletes it once read).
  private func save(_ image: UIImage?) {
    guard let image else {
      finish(nil)
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("receipt-\(UUID().uuidString).jpg")
      do {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
          throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url)
        DispatchQueue.main.async { self.finish(url.path) }
      } catch {
        DispatchQueue.main.async { self.fail("capture-failed", error.localizedDescription) }
      }
    }
  }

  private func finish(_ path: String?) {
    pending?(path)
    pending = nil
  }

  private func fail(_ code: String, _ message: String) {
    pending?(FlutterError(code: code, message: message, details: nil))
    pending = nil
  }

  // MARK: - Recognise

  private func recognize(path: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
        DispatchQueue.main.async {
          result(FlutterError(code: "recognize-failed", message: "Unreadable image.", details: nil))
        }
        return
      }
      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      if #available(iOS 16.0, *) {
        request.automaticallyDetectsLanguage = true
      }
      let handler = VNImageRequestHandler(
        cgImage: cgImage,
        orientation: CGImagePropertyOrientation(image.imageOrientation)
      )
      do {
        try handler.perform([request])
        // Vision's boxes are normalised with the origin bottom-left; they go
        // out in pixels of the upright image, like Android's, so slopes
        // across the page compare the same both ways.
        let width = image.size.width * image.scale
        let height = image.size.height * image.scale
        let lines: [[String: Any]] = (request.results ?? []).compactMap { observation in
          guard let text = observation.topCandidates(1).first?.string else { return nil }
          let box = observation.boundingBox
          return [
            "text": text,
            "left": box.minX * width,
            "top": (1 - box.maxY) * height,
            "right": box.maxX * width,
            "bottom": (1 - box.minY) * height,
          ]
        }
        DispatchQueue.main.async { result(lines) }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "recognize-failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  // MARK: - Helpers

  private static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let windows = scenes.flatMap { $0.windows }
    var top = (windows.first { $0.isKeyWindow } ?? windows.first)?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}

extension CGImagePropertyOrientation {
  fileprivate init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
