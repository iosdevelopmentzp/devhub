import AppKit
import DevHubDomain
import DevHubUI

@MainActor
enum MainMenuBuilder {
    static func build(target: AnyObject, settings: Selector, checkForUpdates: Selector) -> NSMenu {
        let main = NSMenu()
        let settingsItem = item("Settings…", settings, key: ",")
        settingsItem.target = target
        let updatesItem = item("Check for Updates", checkForUpdates)
        updatesItem.target = target
        main.addItem(submenu("DevHub", items: [
            item("About DevHub", #selector(NSApplication.orderFrontStandardAboutPanel(_:))),
            updatesItem,
            .separator(),
            settingsItem,
            .separator(),
            item("Hide DevHub", #selector(NSApplication.hide(_:)), key: "h"),
            item("Quit DevHub", #selector(NSApplication.terminate(_:)), key: "q"),
        ]))
        main.addItem(submenu("File", items: [
            item("Close Window", #selector(NSWindow.performClose(_:)), key: "w"),
        ]))
        main.addItem(submenu("Edit", items: [
            item("Undo", Selector(("undo:")), key: "z"),
            item("Redo", Selector(("redo:")), key: "z", modifiers: [.command, .shift]),
            .separator(),
            item("Cut", #selector(NSText.cut(_:)), key: "x"),
            item("Copy", #selector(NSText.copy(_:)), key: "c"),
            item("Paste", #selector(NSText.paste(_:)), key: "v"),
            item("Select All", #selector(NSText.selectAll(_:)), key: "a"),
        ]))
        let window = submenu("Window", items: [
            item("Minimize", #selector(NSWindow.performMiniaturize(_:)), key: "m"),
            item("Zoom", #selector(NSWindow.performZoom(_:))),
        ])
        main.addItem(window)
        NSApplication.shared.windowsMenu = window.submenu
        return main
    }

    private static func submenu(_ title: String, items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: title)
        items.forEach(menu.addItem)
        item.submenu = menu
        return item
    }

    private static func item(_ title: String, _ action: Selector, key: String = "", modifiers: NSEvent.ModifierFlags = [.command]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        return item
    }
}
