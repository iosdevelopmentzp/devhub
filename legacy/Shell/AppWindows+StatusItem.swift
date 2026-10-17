import AppKit

extension AppWindows {
    func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "hammer.fill", accessibilityDescription: "DevHub")
        item.button?.image?.isTemplate = true
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
    }

    func setStatusTitle(_ text: String) {
        guard let item = statusItem else { return }
        item.button?.title = text.isEmpty ? "" : " " + text
        item.button?.imagePosition = text.isEmpty ? .imageOnly : .imageLeft
        item.length = text.isEmpty ? NSStatusItem.squareLength : NSStatusItem.variableLength
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            showPinnedOrPanel()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(menuItem("Open", #selector(openFromMenu)))
        menu.addItem(menuItem("Pin", #selector(pinFromMenu)))
        menu.addItem(menuItem("Settings", #selector(settingsFromMenu)))
        menu.addItem(.separator())
        menu.addItem(menuItem("Quit", #selector(quitFromMenu)))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    private func menuItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func openFromMenu() {
        showPanel()
    }

    @objc private func pinFromMenu() {
        pin()
    }

    @objc private func settingsFromMenu() {
        navigator.show("settings")
        showPanel()
    }

    @objc private func quitFromMenu() {
        NSApp.terminate(nil)
    }
}
