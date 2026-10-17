import AppKit
import SwiftUI

extension AppWindows {
    func pin() {
        closePanel()
        let window = existingPinnedWindow()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        layout.openCount += 1
        layout.isShown = true
    }

    func unpin() {
        pinnedWindow?.orderOut(nil)
        layout.isShown = false
        showPanel()
    }

    private func existingPinnedWindow() -> NSWindow {
        if let pinnedWindow {
            return pinnedWindow
        }
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: WindowLayout.defaultSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: true
        )
        window.title = "DevHub"
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.contentMinSize = WindowLayout.minimumSize
        let actions = PanelActions(
            isPinned: true,
            togglePin: { [weak self] in self?.unpin() },
            handleEscape: { [weak self] in self?.session.searchText = "" },
            resetPosition: {}
        )
        let controller = NSHostingController(rootView: makeContent(actions))
        controller.sizingOptions = [.minSize]
        window.contentViewController = controller
        if window.setFrameUsingName("DevHubPinnedWindow") == false {
            window.center()
        }
        window.setFrameAutosaveName("DevHubPinnedWindow")
        pinnedWindow = window
        return window
    }
}
