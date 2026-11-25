import Cocoa
import FlutterMacOS

private final class PopupSelection: NSObject {
  var index: Int?
  @objc func selectItem(_ sender: NSMenuItem) { index = sender.tag }
}

class MainFlutterWindow: NSWindow {
  private func registerProjectFiles(_ controller: FlutterViewController) {
    let channel = FlutterMethodChannel(name: "neprosto/project-files", binaryMessenger: controller.engine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      guard ["read", "write"].contains(call.method),
            let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          var url = URL(fileURLWithPath: path)
          if let encoded = args["bookmark"] as? String, let data = Data(base64Encoded: encoded) {
            var stale = false
            url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI],
                          relativeTo: nil, bookmarkDataIsStale: &stale)
          }
          let access = url.startAccessingSecurityScopedResource()
          defer { if access { url.stopAccessingSecurityScopedResource() } }
          func modificationTime() throws -> Double? {
            try url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate?.timeIntervalSince1970
          }
          if call.method == "write", let bytes = args["bytes"] as? FlutterStandardTypedData {
            if let expected = args["modified"] as? Double, try modificationTime() != expected {
              DispatchQueue.main.async {
                result(FlutterError(code: "changed", message: "Файл изменён вне редактора", details: nil))
              }
              return
            }
            try bytes.data.write(to: url, options: .atomic)
            url.removeAllCachedResourceValues()
          }
          let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
          var link: [String: Any] = ["path": url.path, "bookmark": bookmark.base64EncodedString()]
          link["modified"] = try modificationTime()
          if call.method == "read" {
            link["bytes"] = FlutterStandardTypedData(bytes: try Data(contentsOf: url))
          }
          DispatchQueue.main.async { result(link) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "project_file", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
  }

  var workspaceMenuEnabled = false {
    didSet { updateToolbarItems() }
  }

  private var toolbarLabels: [String: String] = [:]
  private let toolbarSymbols = [
    "partsSidebar": "sidebar.left", "inspector": "sidebar.right"
  ]

  private func configureDocumentToolbar(_ args: [String: Any]) {
    guard let name = args["title"] as? String, let edited = args["edited"] as? Bool,
          let labels = args["labels"] as? [String: String] else { return }
    title = name
    isDocumentEdited = edited
    toolbarLabels = labels
    if let panels = args["panels"] as? [String: Bool],
       let viewMenu = NSApp.mainMenu?.items.first(where: { $0.identifier?.rawValue == "np.view" })?.submenu {
      for item in viewMenu.items {
        guard let id = item.identifier?.rawValue, id.hasPrefix("np."),
              let shown = panels[String(id.dropFirst(3))] else { continue }
        item.state = shown ? .on : .off
      }
    }
    if toolbar == nil {
      let bar = NSToolbar(identifier: "neprosto.document")
      bar.delegate = self
      bar.displayMode = .iconOnly
      toolbarStyle = .unified
      toolbar = bar
    }
    updateToolbarItems()
  }

  private func updateToolbarItems() {
    for item in toolbar?.items ?? [] {
      let id = item.itemIdentifier.rawValue
      guard let label = toolbarLabels[id] else { continue }
      item.label = label
      item.toolTip = label
      item.isEnabled = workspaceMenuEnabled
    }
  }

  @objc private func toolbarAction(_ sender: NSToolbarItem) {
    guard sender.isEnabled, workspaceMenuEnabled,
          let controller = contentViewController as? FlutterViewController else { return }
    FlutterMethodChannel(name: "neprosto/editor", binaryMessenger: controller.engine.binaryMessenger)
      .invokeMethod(sender.itemIdentifier.rawValue, arguments: nil)
  }

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
      "drawingSettings:": ("settings", ","), "selectDrawing:": ("selectAll", "a"),
      "terminate:": ("quit", "q")
    ]
    let fileKeys = ["np.new": ("newProject", "n"), "np.open": ("open", "o"),
                      "np.close": ("closeTab", "w"), "np.save": ("save", "s"), "np.saveAs": ("saveAs", "S")]
    for item in menuItems(in: NSApp.mainMenu) {
      guard let selector = item.action,
            let (name, key) = fileKeys[item.identifier?.rawValue ?? ""] ?? actions[NSStringFromSelector(selector)] else { continue }
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
    registerProjectFiles(flutterViewController)

    let popup = FlutterMethodChannel(name: "neprosto/popup", binaryMessenger: flutterViewController.engine.binaryMessenger)
    popup.setMethodCallHandler { [weak self, weak flutterViewController] call, result in
      if call.method == "documentToolbar", let args = call.arguments as? [String: Any], let window = self {
        window.configureDocumentToolbar(args)
        result(true)
        return
      }
      if call.method == "appearance", let args = call.arguments as? [String: Any],
         let theme = args["theme"] as? String, let titles = args["menu"] as? [String: String] {
        let appearance = theme == "system" ? nil : NSAppearance(named: theme == "dark" ? .darkAqua : .aqua)
        if NSApp.appearance != appearance { NSApp.appearance = appearance }
        for item in self?.menuItems(in: NSApp.mainMenu) ?? [] {
          if let key = item.identifier?.rawValue, let title = titles[key] {
            item.title = title
            item.submenu?.title = title
          }
        }
        result(nil)
        return
      }
      if call.method == "workspaceMenuEnabled", let enabled = call.arguments as? Bool {
        self?.workspaceMenuEnabled = enabled
        result(nil)
        return
      }
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
      let checked = Set(args["checked"] as? [Int] ?? [])
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
        item.state = checked.contains(index) ? .on : .off
        item.target = selection
        item.tag = index
      }
      menu.popUp(positioning: nil, at: NSPoint(x: x, y: view.isFlipped ? y : view.bounds.height - y), in: view)
      result(selection.index)
    }

    super.awakeFromNib()
  }
}

extension MainFlutterWindow: NSToolbarDelegate {
  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [.init("partsSidebar"), .flexibleSpace, .init("inspector")]
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return toolbarDefaultItemIdentifiers(toolbar)
  }

  func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
               willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
    let id = identifier.rawValue
    guard let symbol = toolbarSymbols[id], let label = toolbarLabels[id] else { return nil }
    let item = NSToolbarItem(itemIdentifier: identifier)
    item.label = label
    item.toolTip = label
    item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
    item.autovalidates = false
    item.isEnabled = workspaceMenuEnabled
    item.target = self
    item.action = #selector(toolbarAction(_:))
    return item
  }
}
