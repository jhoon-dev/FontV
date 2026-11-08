import Flutter
import UIKit
import CoreText
import CryptoKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  private var fontChannel: FlutterMethodChannel?
  private let fontWorker = DispatchQueue(label: "app.toolmoa.fontv.renderer", qos: .userInitiated)
  private var descriptors: [String: CTFontDescriptor] = [:]
  private var characterSets: [String: CFCharacterSet] = [:]
  private var pendingSave: FlutterResult?
  private var pendingExportURL: URL?
  private enum FontFailure: String, Error {
    case invalid = "FONT_INVALID", tooLarge = "FONT_TOO_LARGE", limit = "FONT_LIMIT"
  }
  private var importDirectory: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return base.appendingPathComponent("FontV-imports", isDirectory: true)
  }
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(name: "app.toolmoa.fontv/fonts",
                                      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    fontChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      #if DEBUG
      case "inspectNativeAdMedia":
        var media: [[String: Any]] = []
        var viewTypes: Set<String> = []
        func inspect(_ view: UIView) {
          let viewType = NSStringFromClass(type(of: view))
          viewTypes.insert(viewType)
          if viewType.hasSuffix("MediaView") {
            media.append(["width": view.bounds.width, "height": view.bounds.height,
                          "visible": !view.isHidden && view.window != nil])
          }
          view.subviews.forEach(inspect)
        }
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
          .flatMap { $0.windows }.forEach(inspect)
        if media.isEmpty {
          result(FlutterError(code: "MEDIA_NOT_MOUNTED", message: "Native media not mounted yet",
                              details: viewTypes.sorted()))
        } else {
          result(media)
        }
      #endif
      case "getFonts":
        // UIKit enumeration stays on the main thread; file and glyph work is serial.
        let fonts: [[String: String]] = UIFont.familyNames.sorted().flatMap { family in
          UIFont.fontNames(forFamilyName: family).sorted().map { name in
            let font = UIFont(name: name, size: 16)
            let style = font?.fontDescriptor.object(forKey: .face) as? String ?? "Regular"
            return ["id": name, "name": name, "family": family, "style": style]
          }
        }
        self.fontWorker.async {
          self.descriptors.removeAll()
          self.characterSets.removeAll()
          for row in fonts {
            if let name = row["id"] { self.descriptors[name] = CTFontDescriptorCreateWithNameAndSize(name as CFString, 16) }
          }
          var rows = fonts.map { $0 as [String: Any] }
          do {
            try FileManager.default.createDirectory(at: self.importDirectory, withIntermediateDirectories: true)
            for url in try FileManager.default.contentsOfDirectory(at: self.importDirectory, includingPropertiesForKeys: nil) where url.pathExtension == "font" {
              if let row = try? self.importedFace(url) { rows.append(row) }
            }
          } catch { /* The system catalog remains usable when local storage is unavailable. */ }
          DispatchQueue.main.async { result(rows) }
        }
      case "saveImage":
        self.saveImage(call.arguments as? [String: Any] ?? [:], result)
      case "renderPreview", "getHangulFonts", "checkGlyphs", "importFont", "removeImportedFont":
        let args = call.arguments as? [String: Any] ?? [:]
        self.fontWorker.async {
          do {
            let value: Any?
            switch call.method {
            case "renderPreview": value = FlutterStandardTypedData(bytes: try self.render(args))
            case "getHangulFonts":
              value = self.descriptors.keys.filter { id in
                guard let set = try? self.characterSet(id) else { return false }
                return (0xac00...0xd7a3).allSatisfy { CFCharacterSetIsLongCharacterMember(set, UInt32($0)) }
              }
            case "checkGlyphs":
              guard let id = args["fontId"] as? String else { throw FontFailure.invalid }
              let set = try self.characterSet(id)
              value = Array((args["codePoints"] as? [Int] ?? []).prefix(1000)).filter {
                $0 < 0 || $0 > 0x10ffff || !CFCharacterSetIsLongCharacterMember(set, UInt32(clamping: $0))
              }
            case "importFont": value = try self.importFont(args)
            default:
              guard let id = args["fontId"] as? String,
                    id.range(of: "^import:[0-9a-f]{64}$", options: .regularExpression) != nil else { throw FontFailure.invalid }
              let url = self.importDirectory.appendingPathComponent(String(id.dropFirst(7)) + ".font")
              if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
              self.descriptors.removeValue(forKey: id); self.characterSets.removeValue(forKey: id)
              value = nil
            }
            DispatchQueue.main.async { result(value) }
          } catch {
            let code = (error as? FontFailure)?.rawValue ?? "FONT_ERROR"
            DispatchQueue.main.async { result(FlutterError(code: code, message: "Font operation failed", details: nil)) }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func characterSet(_ id: String) throws -> CFCharacterSet {
    if let cached = characterSets[id] { return cached }
    guard let descriptor = descriptors[id] else { throw FontFailure.invalid }
    let set = CTFontCopyCharacterSet(CTFontCreateWithFontDescriptor(descriptor, 16, nil))
    characterSets[id] = set
    return set
  }

  private func importedFace(_ url: URL) throws -> [String: Any] {
    let size = (try url.resourceValues(forKeys: [.fileSizeKey])).fileSize ?? Int.max
    guard size <= 32 * 1024 * 1024 else { throw FontFailure.tooLarge }
    let data = try Data(contentsOf: url)
    guard let descriptor = CTFontManagerCreateFontDescriptorFromData(data as CFData) else { throw FontFailure.invalid }
    let font = CTFontCreateWithFontDescriptor(descriptor, 16, nil)
    let id = "import:" + url.deletingPathExtension().lastPathComponent
    descriptors[id] = descriptor
    return ["id": id, "name": CTFontCopyPostScriptName(font) as String,
            "family": CTFontCopyFamilyName(font) as String,
            "style": (CTFontDescriptorCopyAttribute(descriptor, kCTFontStyleNameAttribute) as? String) ?? "Regular",
            "imported": true]
  }

  private func importFont(_ args: [String: Any]) throws -> [String: Any] {
    guard let typed = args["bytes"] as? FlutterStandardTypedData else { throw FontFailure.invalid }
    let data = typed.data
    guard data.count <= 32 * 1024 * 1024 else { throw FontFailure.tooLarge }
    let signature = Array(data.prefix(4))
    guard data.count >= 12, [[0, 1, 0, 0], [79, 84, 84, 79], [116, 114, 117, 101]].contains(signature.map { Int($0) }),
          CTFontManagerCreateFontDescriptorFromData(data as CFData) != nil else { throw FontFailure.invalid }
    try FileManager.default.createDirectory(at: importDirectory, withIntermediateDirectories: true)
    let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    let target = importDirectory.appendingPathComponent(digest + ".font")
    if FileManager.default.fileExists(atPath: target.path) { return try importedFace(target) }
    let files = try FileManager.default.contentsOfDirectory(at: importDirectory, includingPropertiesForKeys: [.fileSizeKey]).filter { $0.pathExtension == "font" }
    let total = try files.reduce(0) { $0 + ((try $1.resourceValues(forKeys: [.fileSizeKey])).fileSize ?? 0) }
    guard files.count < 50 && total + data.count <= 100 * 1024 * 1024 else { throw FontFailure.limit }
    try data.write(to: target, options: .atomic)
    return try importedFace(target)
  }

  private func render(_ args: [String: Any]) throws -> Data {
    guard let id = args["fontId"] as? String, let descriptor = descriptors[id],
          let text = args["text"] as? String, let size = args["size"] as? NSNumber,
          let width = args["width"] as? NSNumber, let height = args["height"] as? NSNumber,
          let scale = args["scale"] as? NSNumber, let argb = args["color"] as? NSNumber else { throw FontFailure.invalid }
    let canvasSize = CGSize(width: min(1600, max(1, width.doubleValue)), height: min(1600, max(1, height.doubleValue)))
    let font = CTFontCreateWithFontDescriptor(descriptor, CGFloat(min(120, max(8, size.doubleValue))), nil)
    var alignment: CTTextAlignment = args["alignment"] as? String == "center" ? .center : (args["alignment"] as? String == "right" ? .right : .left)
    var heightMultiple = CGFloat(min(2.5, max(1, (args["lineHeight"] as? NSNumber)?.doubleValue ?? 1.35)))
    var direction = CTWritingDirection.leftToRight
    let paragraph = withUnsafePointer(to: &alignment) { alignmentPointer in
      withUnsafePointer(to: &heightMultiple) { heightPointer in
        withUnsafePointer(to: &direction) { directionPointer in
          var settings = [
            CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout<CTTextAlignment>.size, value: alignmentPointer),
            CTParagraphStyleSetting(spec: .lineHeightMultiple, valueSize: MemoryLayout<CGFloat>.size, value: heightPointer),
            CTParagraphStyleSetting(spec: .baseWritingDirection, valueSize: MemoryLayout<CTWritingDirection>.size, value: directionPointer),
          ]
          return CTParagraphStyleCreate(&settings, settings.count)
        }
      }
    }
    let value = argb.uint32Value
    let color = UIColor(red: CGFloat((value >> 16) & 255) / 255, green: CGFloat((value >> 8) & 255) / 255,
                        blue: CGFloat(value & 255) / 255, alpha: CGFloat((value >> 24) & 255) / 255)
    let attributed = NSAttributedString(string: String(text.prefix(1000)), attributes: [
      NSAttributedString.Key(kCTFontAttributeName as String): font,
      NSAttributedString.Key(kCTForegroundColorAttributeName as String): color.cgColor,
      NSAttributedString.Key(kCTParagraphStyleAttributeName as String): paragraph,
      NSAttributedString.Key(kCTKernAttributeName as String): min(12, max(-2, (args["letterSpacing"] as? NSNumber)?.doubleValue ?? 0)),
    ])
    return autoreleasepool {
      let format = UIGraphicsImageRendererFormat()
      format.opaque = false; format.scale = CGFloat(min(3, max(1, scale.doubleValue)))
      return UIGraphicsImageRenderer(size: canvasSize, format: format).pngData { renderer in
        let context = renderer.cgContext
        context.textMatrix = .identity
        context.translateBy(x: 0, y: canvasSize.height); context.scaleBy(x: 1, y: -1)
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let path = CGPath(rect: CGRect(origin: .zero, size: canvasSize), transform: nil)
        CTFrameDraw(CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil), context)
      }
    }
  }

  private func saveImage(_ args: [String: Any], _ result: @escaping FlutterResult) {
    guard pendingSave == nil else { result(FlutterError(code: "IMAGE_BUSY", message: "Save is already open", details: nil)); return }
    guard let bytes = (args["bytes"] as? FlutterStandardTypedData)?.data,
          bytes.count <= 32 * 1024 * 1024, Array(bytes.prefix(8)) == [137, 80, 78, 71, 13, 10, 26, 10] else {
      result(FlutterError(code: "IMAGE_INVALID", message: "Invalid PNG", details: nil)); return
    }
    do {
      let filename = URL(fileURLWithPath: (args["filename"] as? String) ?? "FontV.png").lastPathComponent
      let folder = FileManager.default.temporaryDirectory.appendingPathComponent("FontV-export", isDirectory: true)
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      let url = folder.appendingPathComponent(filename)
      try bytes.write(to: url, options: .atomic)
      guard var presenter = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
        .filter({ $0.activationState == .foregroundActive }).flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.rootViewController else {
        try? FileManager.default.removeItem(at: url)
        result(FlutterError(code: "IMAGE_SAVE", message: "No active window", details: nil)); return
      }
      while let presented = presenter.presentedViewController { presenter = presented }
      pendingSave = result; pendingExportURL = url
      let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
      picker.delegate = self
      picker.modalPresentationStyle = .formSheet
      presenter.present(picker, animated: true)
    } catch { result(FlutterError(code: "IMAGE_SAVE", message: "Could not save PNG", details: nil)) }
  }
  private func finishSave(_ saved: Bool) {
    let result = pendingSave; pendingSave = nil
    if let url = pendingExportURL { try? FileManager.default.removeItem(at: url) }
    pendingExportURL = nil
    result?(saved)
  }
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { finishSave(true) }
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { finishSave(false) }
}
