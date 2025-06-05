import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    Task { @MainActor in
      let flutterViewController = FlutterViewController()
      let windowFrame = self.frame
      self.contentViewController = flutterViewController
      self.setFrame(windowFrame, display: true)

      RegisterGeneratedPlugins(registry: flutterViewController)
    }

    super.awakeFromNib()
  }
}
