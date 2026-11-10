import Cocoa
import FlutterMacOS
import CoreText
import CryptoKit
import ImageIO

class MainFlutterWindow: NSWindow {
  private var fontService: DesktopFontService?
  override func awakeFromNib() {
    let controller = FlutterViewController()
    contentViewController = controller
    setContentSize(NSSize(width: 1280, height: 800))
    minSize = NSSize(width: 640, height: 540)
    center()
    RegisterGeneratedPlugins(registry: controller)
    fontService = DesktopFontService(messenger: controller.engine.binaryMessenger)
    super.awakeFromNib()
  }
}

// All descriptors and coverage caches belong to this serial queue.
private final class DesktopFontService {
  private let channel: FlutterMethodChannel
  private let worker = DispatchQueue(label: "app.toolmoa.fontv.renderer", qos: .userInitiated)
  private var descriptors: [String: CTFontDescriptor] = [:]
  private var characterSets: [String: CFCharacterSet] = [:]
  private var hangul: [String: Bool] = [:]
  private enum FontFailure: String, Error {
    case invalid = "FONT_INVALID", tooLarge = "FONT_TOO_LARGE", limit = "FONT_LIMIT"
  }
  private var importDirectory: URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("FontV-imports", isDirectory: true)
  }
  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "app.toolmoa.fontv/fonts", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      guard ["getFonts", "renderPreview", "getHangulFonts", "checkGlyphs", "importFont", "removeImportedFont"].contains(call.method) else {
        result(FlutterMethodNotImplemented); return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      self.worker.async {
        autoreleasepool {
          do {
            let value: Any?
            switch call.method {
            case "getFonts": value = try self.loadFonts()
            case "renderPreview": value = FlutterStandardTypedData(bytes: try self.render(args))
            case "getHangulFonts":
              value = self.descriptors.keys.filter { id in
                if let cached = self.hangul[id] { return cached }
                guard let set = try? self.characterSet(id) else { return false }
                let complete = (0xac00...0xd7a3).allSatisfy { CFCharacterSetIsLongCharacterMember(set, UInt32($0)) }
                self.hangul[id] = complete
                return complete
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
              self.descriptors.removeValue(forKey: id)
              self.characterSets.removeValue(forKey: id)
              self.hangul.removeValue(forKey: id)
              value = nil
            }
            DispatchQueue.main.async { result(value) }
          } catch {
            let code = (error as? FontFailure)?.rawValue ?? "FONT_ERROR"
            DispatchQueue.main.async { result(FlutterError(code: code, message: "Font operation failed", details: nil)) }
          }
        }
      }
    }
  }
  private func loadFonts() throws -> [[String: Any]] {
    descriptors.removeAll(); characterSets.removeAll(); hangul.removeAll()
    let collection = CTFontCollectionCreateFromAvailableFonts(nil)
    let available = CTFontCollectionCreateMatchingFontDescriptors(collection) as? [CTFontDescriptor] ?? []
    var rows: [[String: Any]] = []
    for descriptor in available {
      let font = CTFontCreateWithFontDescriptor(descriptor, 16, nil)
      let id = CTFontCopyPostScriptName(font) as String
      guard descriptors[id] == nil else { continue }
      descriptors[id] = descriptor
      rows.append(["id": id, "name": id, "family": CTFontCopyFamilyName(font) as String,
                   "style": (CTFontDescriptorCopyAttribute(descriptor, kCTFontStyleNameAttribute) as? String) ?? "Regular"])
    }
    do {
      try FileManager.default.createDirectory(at: importDirectory, withIntermediateDirectories: true)
      for url in try FileManager.default.contentsOfDirectory(at: importDirectory, includingPropertiesForKeys: nil) where url.pathExtension == "font" {
        if let row = try? importedFace(url) { rows.append(row) }
      }
    } catch { /* System fonts remain available when import storage cannot be read. */ }
    return rows
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
    guard url.deletingPathExtension().lastPathComponent.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil else { throw FontFailure.invalid }
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
    let color = NSColor(red: CGFloat((value >> 16) & 255) / 255, green: CGFloat((value >> 8) & 255) / 255,
                        blue: CGFloat(value & 255) / 255, alpha: CGFloat((value >> 24) & 255) / 255)
    let attributed = NSAttributedString(string: String(text.prefix(1000)), attributes: [
      NSAttributedString.Key(kCTFontAttributeName as String): font,
      NSAttributedString.Key(kCTForegroundColorAttributeName as String): color.cgColor,
      NSAttributedString.Key(kCTParagraphStyleAttributeName as String): paragraph,
      NSAttributedString.Key(kCTKernAttributeName as String): min(12, max(-2, (args["letterSpacing"] as? NSNumber)?.doubleValue ?? 0)),
    ])
    let renderScale = CGFloat(min(3, max(1, scale.doubleValue)))
    let pixelWidth = Int(ceil(canvasSize.width * renderScale))
    let pixelHeight = Int(ceil(canvasSize.height * renderScale))
    guard let context = CGContext(data: nil, width: pixelWidth, height: pixelHeight,
                                  bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw FontFailure.invalid }
    context.scaleBy(x: renderScale, y: renderScale)
    context.textMatrix = .identity
    let framesetter = CTFramesetterCreateWithAttributedString(attributed)
    let path = CGPath(rect: CGRect(origin: .zero, size: canvasSize), transform: nil)
    CTFrameDraw(CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil), context)
    guard let image = context.makeImage() else { throw FontFailure.invalid }
    let png = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(png, "public.png" as CFString, 1, nil) else { throw FontFailure.invalid }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw FontFailure.invalid }
    return png as Data
  }
}
