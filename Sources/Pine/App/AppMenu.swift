import AppKit

/// Pine's menus, for when it shows in the Dock and is an ordinary app: its
/// app menu, an Edit menu (so ⌘C, ⌘V and ⌘A work while typing a hex code),
/// and the Dock icon's menu. In the menu bar alone, macOS shows none of them.
@MainActor
enum AppMenu {
    static func make(target: AnyObject) -> NSMenu {
        let main = NSMenu()

        let app = NSMenu(title: "Pine")
        app.addItem(item("Pick Colour", #selector(AppDelegate.menuPickColour), target: target))
        app.addItem(item("Show App", #selector(AppDelegate.menuShowApp), target: target))
        app.addItem(.separator())
        app.addItem(item("Settings…", #selector(AppDelegate.menuSettings), key: ",", target: target))
        app.addItem(.separator())
        app.addItem(item("Hide Pine", #selector(NSApplication.hide(_:)), key: "h"))
        app.addItem(item("Quit Pine", #selector(NSApplication.terminate(_:)), key: "q"))
        main.addItem(submenu(app))

        let edit = NSMenu(title: "Edit")
        edit.addItem(item("Undo", Selector(("undo:")), key: "z"))
        edit.addItem(item("Redo", Selector(("redo:")), key: "Z"))
        edit.addItem(.separator())
        edit.addItem(item("Cut", #selector(NSText.cut(_:)), key: "x"))
        edit.addItem(item("Copy", #selector(NSText.copy(_:)), key: "c"))
        edit.addItem(item("Paste", #selector(NSText.paste(_:)), key: "v"))
        edit.addItem(item("Select All", #selector(NSText.selectAll(_:)), key: "a"))
        main.addItem(submenu(edit))

        let window = NSMenu(title: "Window")
        window.addItem(item("Close", #selector(NSWindow.performClose(_:)), key: "w"))
        window.addItem(item("Minimise", #selector(NSWindow.performMiniaturize(_:)), key: "m"))
        main.addItem(submenu(window))
        NSApp.windowsMenu = window
        return main
    }

    static func dock(target: AnyObject) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(item("Pick Colour", #selector(AppDelegate.menuPickColour), target: target))
        menu.addItem(item("Show App", #selector(AppDelegate.menuShowApp), target: target))
        menu.addItem(item("Settings…", #selector(AppDelegate.menuSettings), target: target))
        return menu
    }

    private static func item(_ title: String, _ action: Selector, key: String = "", target: AnyObject? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = target
        return item
    }

    private static func submenu(_ menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: menu.title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }
}
