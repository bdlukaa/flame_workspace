import Cocoa
import FlutterMacOS

enum EditorWindowPlacement {
  static func frame(saved: CGRect?, visibleFrames: [CGRect]) -> CGRect {
    let screens = visibleFrames.filter { $0.width > 0 && $0.height > 0 }
    guard let primary = screens.first else { return CGRect(x: 0, y: 0, width: 1200, height: 800) }
    let desired = saved.flatMap { rect -> CGRect? in
      guard rect.origin.x.isFinite, rect.origin.y.isFinite,
            rect.width.isFinite, rect.height.isFinite,
            rect.width >= 480, rect.height >= 360 else { return nil }
      return rect
    }
    let screen = desired.flatMap { rect in
      screens.max { intersectionArea($0, rect) < intersectionArea($1, rect) }
    } ?? primary
    let reachable = desired.map { intersectionArea(screen, $0) > 0 } ?? false
    let target = reachable ? screen : primary
    let width = min(desired?.width ?? 1440, target.width)
    let height = min(desired?.height ?? 900, target.height)
    let x = reachable && desired != nil
      ? min(max(desired!.minX, target.minX), target.maxX - width)
      : target.midX - width / 2
    let y = reachable && desired != nil
      ? min(max(desired!.minY, target.minY), target.maxY - height)
      : target.midY - height / 2
    return CGRect(x: x, y: y, width: width, height: height)
  }

  private static func intersectionArea(_ a: CGRect, _ b: CGRect) -> CGFloat {
    let intersection = a.intersection(b)
    return intersection.isNull ? 0 : intersection.width * intersection.height
  }
}

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var exitApproved = false
  private var closeInProgress = false
  private var windowChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    contentViewController = flutterViewController
    styleMask.insert(.fullSizeContentView)
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    isMovableByWindowBackground = false
    let channel = FlutterMethodChannel(name: "flameWorkspace/window", binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "drag" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self = self, let event = NSApp.currentEvent,
            event.type == .leftMouseDown || event.type == .leftMouseDragged else {
        result(FlutterError(code: "drag_unavailable", message: "No active window drag event.", details: nil))
        return
      }
      self.performDrag(with: event)
      result(nil)
    }
    windowChannel = channel
    delegate = self

    let autosaveName = "FlameWorkspaceEditor"
    setFrameAutosaveName(autosaveName)
    let restored = setFrameUsingName(autosaveName) ? frame : nil
    setFrame(EditorWindowPlacement.frame(saved: restored, visibleFrames: NSScreen.screens.map(\.visibleFrame)), display: true)
    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }

  func requestExit(_ completion: @escaping (Bool) -> Void) {
    if exitApproved { completion(true); return }
    guard let channel = windowChannel else { completion(false); return }
    channel.invokeMethod("requestClose", arguments: nil) { [weak self] response in
      let approved = response as? Bool == true
      if approved { self?.exitApproved = true }
      completion(approved)
    }
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    if exitApproved { return true }
    if !closeInProgress {
      closeInProgress = true
      requestExit { [weak self] approved in
        guard let self = self else { return }
        self.closeInProgress = false
        if approved { self.performClose(nil) }
      }
    }
    return false
  }
}
