import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var fontChannel: FlutterMethodChannel?
  private let fontWorker = DispatchQueue(label: "app.toolmoa.fontv.renderer", qos: .userInitiated)
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
        // UIKit enumeration happens on the main thread. No downloaded or private fonts.
        let fonts: [[String: String]] = UIFont.familyNames.sorted().flatMap { family in
          UIFont.fontNames(forFamilyName: family).sorted().map { name in
            let font = UIFont(name: name, size: 16)
            let style = font?.fontDescriptor.object(forKey: .face) as? String ?? "Regular"
            return ["id": name, "name": name, "family": family, "style": style]
          }
        }
        result(fonts)
      case "renderPreview":
        guard let args = call.arguments as? [String: Any],
              let name = args["fontId"] as? String,
              let text = args["text"] as? String,
              let size = args["size"] as? NSNumber,
              let width = args["width"] as? NSNumber,
              let height = args["height"] as? NSNumber,
              let scale = args["scale"] as? NSNumber,
              let argb = args["color"] as? NSNumber,
              let font = UIFont(name: name, size: CGFloat(min(120, max(8, size.doubleValue)))) else {
          result(FlutterError(code: "FONT_ERROR", message: "Invalid font preview request", details: nil))
          return
        }
        let canvasSize = CGSize(width: min(1600, max(1, width.doubleValue)),
                                height: min(1600, max(1, height.doubleValue)))
        let renderScale = CGFloat(min(3, max(1, scale.doubleValue)))
        let value = argb.uint32Value
        let color = UIColor(red: CGFloat((value >> 16) & 255) / 255,
                            green: CGFloat((value >> 8) & 255) / 255,
                            blue: CGFloat(value & 255) / 255,
                            alpha: CGFloat((value >> 24) & 255) / 255)
        self.fontWorker.async {
          autoreleasepool {
            let format = UIGraphicsImageRendererFormat()
            format.opaque = false
            format.scale = renderScale
            let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineHeightMultiple = 1.35
            paragraph.lineBreakMode = .byWordWrapping
            let data = renderer.pngData { _ in
              (String(text.prefix(1000)) as NSString).draw(
                with: CGRect(origin: .zero, size: canvasSize),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph],
                context: nil)
            }
            DispatchQueue.main.async { result(FlutterStandardTypedData(bytes: data)) }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
