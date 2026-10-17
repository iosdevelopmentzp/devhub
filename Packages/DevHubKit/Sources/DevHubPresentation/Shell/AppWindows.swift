import AppKit
import SwiftUI
import DevHubDomain
import DevHubUI

@MainActor
package final class AppWindows: NSObject {
    private let assembly: PresentationAssembly
    private let statusItem: NSStatusItem
    let panel: MenuBarPanel
    private var pinnedWindow: NSWindow?
    private var mergeRequestWindows: [MergeRequestSummary.ID: NSWindow] = [:]
    private var clickMonitor: Any?
    private var resignObserver: NSObjectProtocol?
    private var lastPanelTopLeft: CGPoint?

    private var layout: WindowLayout {
        assembly.layout
    }

    var isPinnedVisible: Bool {
        pinnedWindow?.isVisible == true
    }

    package init(assembly: PresentationAssembly) {
        self.assembly = assembly
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        panel = MenuBarPanel()
        super.init()
    }

    package func start() {
        lastPanelTopLeft = layout.panelTopLeft
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
            button.imagePosition = .imageLeading
        }
        updateStatusLabel()
        observeLayout()
        assembly.usage.startPolling()
        assembly.openMergeRequests.startPolling()
        Task { [assembly] in
            await assembly.mockSets.load()
            assembly.mockServer.restoreServers()
        }
        resignObserver = NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.closePanel()
            }
        }
    }

    func togglePanel() {
        if panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    package func showPinnedOrPanel() {
        if let pinnedWindow, pinnedWindow.isVisible {
            NSApp.activate()
            pinnedWindow.makeKeyAndOrderFront(nil)
            return
        }
        togglePanel()
    }

    func togglePin() {
        if let pinnedWindow, pinnedWindow.isVisible {
            pinnedWindow.close()
            return
        }
        closePanel()
        showPinnedWindow()
    }

    func showMergeRequestWindow(_ summary: MergeRequestSummary) {
        closePanel()
        let window: NSWindow
        if let existing = mergeRequestWindows[summary.id], existing.isVisible {
            window = existing
        } else {
            window = makeMergeRequestWindow(summary)
            mergeRequestWindows[summary.id] = window
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func statusItemClicked() {
        togglePanel()
    }

    func showPanel() {
        if panel.contentViewController == nil {
            panel.contentViewController = hostingController(isPinned: false)
        } else {
            layout.openCount += 1
        }
        panel.setFrame(layout.panelFrame(anchor: iconAnchor(), anchorScreen: statusItem.button?.window?.screen), display: false)
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
        statusItem.button?.highlight(true)
        installClickMonitor()
    }

    private func closePanel() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        statusItem.button?.highlight(false)
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
    }

    private func installClickMonitor() {
        guard clickMonitor == nil else { return }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.closePanel()
            }
        }
    }

    private func iconAnchor() -> CGPoint {
        guard let button = statusItem.button, let window = button.window else {
            let visible = NSScreen.main?.visibleFrame ?? .zero
            return CGPoint(x: visible.maxX - layout.size.width, y: visible.maxY)
        }
        let frame = window.convertToScreen(button.convert(button.bounds, to: nil))
        return CGPoint(x: frame.midX - layout.size.width / 2, y: frame.minY - 4)
    }

    private func showPinnedWindow() {
        if pinnedWindow != nil {
            layout.openCount += 1
        }
        let window = pinnedWindow ?? makePinnedWindow()
        pinnedWindow = window
        if window.setFrameUsingName(WindowLayout.pinnedAutosaveName) == false {
            window.setContentSize(layout.size)
            window.center()
        }
        window.setFrameAutosaveName(WindowLayout.pinnedAutosaveName)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makePinnedWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: layout.size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DevHub"
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.contentMinSize = WindowLayout.minimumSize
        window.contentViewController = hostingController(isPinned: true)
        return window
    }

    private func makeMergeRequestWindow(_ summary: MergeRequestSummary) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: NSSize(width: 860, height: 720)),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "!\(summary.iid) \(summary.title)"
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .aqua)
        window.contentMinSize = NSSize(width: 640, height: 400)
        let root = MergeRequestWindowView(summary: summary)
            .inject(assembly)
            .colorScheme(.light)
        window.contentViewController = NSHostingController(rootView: root)
        if window.setFrameUsingName(WindowLayout.mergeRequestAutosaveName) == false {
            window.center()
        }
        window.setFrameAutosaveName(WindowLayout.mergeRequestAutosaveName)
        return window
    }

    private func hostingController(isPinned: Bool) -> NSViewController {
        let root = RootView()
            .inject(assembly)
            .environment(\.isPinnedWindow, isPinned)
            .environment(\.togglePin, { [weak self] in self?.togglePin() })
            .environment(\.openMergeRequestWindow, { [weak self] in self?.showMergeRequestWindow($0) })
        let controller = NSHostingController(rootView: root)
        controller.sizingOptions = isPinned ? [.minSize] : []
        return controller
    }

    private func observeLayout() {
        withObservationTracking {
            _ = layout.size
            _ = layout.panelTopLeft
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                applyLayout()
                observeLayout()
            }
        }
    }

    private func applyLayout() {
        let returnsToIcon = lastPanelTopLeft != nil && layout.panelTopLeft == nil
        lastPanelTopLeft = layout.panelTopLeft
        guard panel.isVisible else { return }
        if returnsToIcon {
            panel.setFrame(layout.panelFrame(anchor: iconAnchor(), anchorScreen: statusItem.button?.window?.screen), display: true)
            return
        }
        layout.fit(panel)
    }

    private func updateStatusLabel() {
        withObservationTracking {
            let usage = assembly.usage
            let settings = assembly.settings
            let image = NSImage(systemSymbolName: "hammer.fill", accessibilityDescription: "DevHub")
            image?.isTemplate = true
            statusItem.button?.image = image
            statusItem.button?.title = StatusItemTitle.text(
                usage: settings.values.showUsageInMenuBar ? usage.usage?.limits.first?.percentText : nil,
                reviewCount: settings.values.showReviewCountInMenuBar ? assembly.openMergeRequests.reviewCount : nil
            )
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                self?.updateStatusLabel()
            }
        }
    }
}
