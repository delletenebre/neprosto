import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate, NSMenuItemValidation {
  private func performEditorCommand(_ command: String) {
    guard let view = mainFlutterWindow?.contentViewController as? FlutterViewController else { return }
    FlutterMethodChannel(name: "neprosto/editor", binaryMessenger: view.engine.binaryMessenger)
      .invokeMethod(command, arguments: nil)
  }

  @IBAction func workspaceCommand(_ sender: NSMenuItem) {
    guard let id = sender.identifier?.rawValue, id.hasPrefix("np.") else { return }
    performEditorCommand(String(id.dropFirst(3)))
  }

  func validateMenuItem(_ item: NSMenuItem) -> Bool {
    if item.action == #selector(workspaceCommand(_:)) || item.action == #selector(drawingSettings(_:)) {
      return (mainFlutterWindow as? MainFlutterWindow)?.workspaceMenuEnabled == true
    }
    return true
  }

  @IBAction func undoDrawing(_ sender: Any?) { performEditorCommand("undo") }
  @IBAction func redoDrawing(_ sender: Any?) { performEditorCommand("redo") }
  @IBAction func selectDrawing(_ sender: Any?) { performEditorCommand("selectAll") }
  @IBAction func drawingSettings(_ sender: Any?) { performEditorCommand("settings") }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
