import AppKit
import SwiftUI

@MainActor
final class AppWindows: NSObject {
    let layout: WindowLayout
    let settings: SettingsStore
    let navigator: Navigator
    let session: ProjectSession
    let makeContent: (PanelActions) -> AnyView

    var statusItem: NSStatusItem?
    var panel: MenuBarPanel?
    var pinnedWindow: NSWindow?
    var clickMonitor: Any?
    var resignObserver: NSObjectProtocol?
    let hotKey = GlobalHotKey()

    init(layout: WindowLayout, settings: SettingsStore, navigator: Navigator, session: ProjectSession, makeContent: @escaping (PanelActions) -> AnyView) {
        self.layout = layout
        self.settings = settings
        self.navigator = navigator
        self.session = session
        self.makeContent = makeContent
        super.init()
        installStatusItem()
        observeSystem()
        applySettings()
    }

    var isPanelVisible: Bool { panel?.isVisible == true }
    var isPinnedVisible: Bool { pinnedWindow?.isVisible == true }

    func togglePanel() {
        if isPanelVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    func showPanel() {
        let panel = existingPanel()
        fitPanel()
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        layout.openCount += 1
        layout.isShown = true
        statusItem?.button?.highlight(true)
        installClickMonitor()
    }

    func closePanel() {
        panel?.orderOut(nil)
        layout.isShown = false
        statusItem?.button?.highlight(false)
        removeClickMonitor()
    }

    func showPinnedOrPanel() {
        if isPinnedVisible {
            NSApp.activate()
            pinnedWindow?.makeKeyAndOrderFront(nil)
        } else {
            togglePanel()
        }
    }

    func handleEscape() {
        if session.isSearching {
            session.searchText = ""
        } else if isPanelVisible {
            closePanel()
        }
    }

    func fitPanel() {
        guard let panel else { return }
        let frame = layout.panelFrame(anchor: anchorFrame(), visibleFrames: NSScreen.screens.map(\.visibleFrame))
        panel.setFrame(frame, display: true)
    }

    private func existingPanel() -> MenuBarPanel {
        if let panel {
            return panel
        }
        let created = MenuBarPanel()
        let actions = PanelActions(
            isPinned: false,
            togglePin: { [weak self] in self?.pin() },
            handleEscape: { [weak self] in self?.handleEscape() },
            resetPosition: { [weak self] in self?.resetPosition() }
        )
        let controller = NSHostingController(rootView: makeContent(actions))
        controller.sizingOptions = []
        created.contentViewController = controller
        created.onCancel = { [weak self] in
            guard let self else { return }
            handleEscape()
        }
        panel = created
        return created
    }

    private func resetPosition() {
        layout.resetPosition()
        fitPanel()
    }

    private func anchorFrame() -> CGRect? {
        guard let button = statusItem?.button, let window = button.window else { return nil }
        return window.convertToScreen(button.convert(button.bounds, to: nil))
    }
}
