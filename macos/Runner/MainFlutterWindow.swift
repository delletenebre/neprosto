import Cocoa
import FlutterMacOS

private final class PopupSelection: NSObject {
  var index: Int?
  @objc func selectItem(_ sender: NSMenuItem) { index = sender.tag }
}

class MainFlutterWindow: NSWindow {
  private var suspendedKeys: [(NSMenuItem, String)] = []

  private func menuItems(in menu: NSMenu?) -> [NSMenuItem] {
    guard let menu = menu else { return [] }
    return menu.items.flatMap { [$0] + menuItems(in: $0.submenu) }
  }

  private func captureShortcut(_ active: Bool) {
    if active && suspendedKeys.isEmpty {
      for item in menuItems(in: NSApp.mainMenu) where !item.keyEquivalent.isEmpty {
        suspendedKeys.append((item, item.keyEquivalent))
        item.keyEquivalent = ""
      }
    } else if !active {
      for (item, key) in suspendedKeys { item.keyEquivalent = key }
      suspendedKeys.removeAll()
    }
  }

  private func configureEditorShortcuts(_ defaults: [String: Bool]) {
    let actions = [
      "undoDrawing:": ("undo", "z"), "redoDrawing:": ("redo", "Z"),
      "drawingSettings:": ("settings", ","), "selectDrawing:": ("selectAll", "a")
    ]
    for item in menuItems(in: NSApp.mainMenu) {
      guard let selector = item.action, let (name, key) = actions[NSStringFromSelector(selector)] else { continue }
      item.keyEquivalent = defaults[name] == true ? key : ""
    }
  }

  private func setShortcut(_ shortcut: String, for item: NSMenuItem) {
    let key = shortcut.filter { !"⇧⌘⌥".contains($0) }
    let special = ["⌫": "\u{8}", "Del": "\u{F728}", "Tab": "\t",
                   "←": "\u{F702}", "→": "\u{F703}", "↑": "\u{F700}", "↓": "\u{F701}"]
    if let equivalent = special[key] {
      item.keyEquivalent = equivalent
    } else if key.count == 1 {
      item.keyEquivalent = key.lowercased()
    } else if key.first == "F", let number = Int(key.dropFirst()), (1...12).contains(number),
              let scalar = UnicodeScalar(0xF703 + number) {
      item.keyEquivalent = String(scalar)
    } else { return }
    item.keyEquivalentModifierMask = []
    if shortcut.contains("⌘") { item.keyEquivalentModifierMask.insert(.command) }
    if shortcut.contains("⇧") { item.keyEquivalentModifierMask.insert(.shift) }
    if shortcut.contains("⌥") { item.keyEquivalentModifierMask.insert(.option) }
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let screenSize = screen?.visibleFrame.size ?? NSSize(width: 1280, height: 800)
    self.contentViewController = flutterViewController
    self.minSize = NSSize(width: 880, height: 570)
    self.setContentSize(NSSize(width: min(1380, screenSize.width * 0.94), height: min(870, screenSize.height * 0.88)))
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    let popup = FlutterMethodChannel(name: "neprosto/popup", binaryMessenger: flutterViewController.engine.binaryMessenger)
    popup.setMethodCallHandler { [weak self, weak flutterViewController] call, result in
      if call.method == "editorShortcuts", let defaults = call.arguments as? [String: Bool] {
        self?.configureEditorShortcuts(defaults)
        result(nil)
        return
      }
      if call.method == "captureShortcut", let active = call.arguments as? Bool {
        self?.captureShortcut(active)
        result(nil)
        return
      }
      guard ["choose", "contextMenu"].contains(call.method), let view = flutterViewController?.view,
            let args = call.arguments as? [String: Any], let labels = args["items"] as? [String],
            let x = args["x"] as? Double, let y = args["y"] as? Double else {
        result(FlutterMethodNotImplemented)
        return
      }
      let menu = NSMenu()
      let selection = PopupSelection()
      if let heading = args["heading"] as? String {
        let header = NSMenuItem(title: heading, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
      }
      let dividers = Set(args["dividers"] as? [Int] ?? [])
      let symbols = args["symbols"] as? [String] ?? []
      let shortcuts = args["shortcuts"] as? [String] ?? []
      for (index, label) in labels.enumerated() {
        if dividers.contains(index) { menu.addItem(.separator()) }
        let item = menu.addItem(withTitle: label, action: #selector(PopupSelection.selectItem(_:)), keyEquivalent: "")
        if symbols.indices.contains(index), !symbols[index].isEmpty {
          item.image = NSImage(systemSymbolName: symbols[index], accessibilityDescription: nil)
        }
        if shortcuts.indices.contains(index) {
          self?.setShortcut(shortcuts[index], for: item)
        }
        item.target = selection
        item.tag = index
      }
      menu.popUp(positioning: nil, at: NSPoint(x: x, y: view.isFlipped ? y : view.bounds.height - y), in: view)
      result(selection.index)
    }

    super.awakeFromNib()
  }
}
