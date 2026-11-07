import AppKit
import SwiftUI
import DevHubDomain
import DevHubUI

@MainActor
package final class AppWindows: NSObject, NSWindowDelegate {
    private let assembly: PresentationAssembly
    private let statusItem: NSStatusItem
    let panel: MenuBarPanel
    private var pinnedWindow: NSWindow?
    private var mainWindow: MainWindow?
    private var pullRequestWindows: [PullRequestSummary.ID: NSWindow] = [:]
    private var clickMonitor: Any?
    private var resignObserver: NSObjectProtocol?
    private var pinnedCloseObserver: NSObjectProtocol?
    private var lastPanelTopLeft: CGPoint?
    private var activationObservers: [NSObjectProtocol] = []

    private var layout: WindowLayout {
        assembly.layout
    }

    var isPinnedVisible: Bool {
        pinnedWindow?.isVisible == true
    }

    var visibleContentView: NSView? {
        mode == .window ? mainWindow?.contentView : panel.contentView
    }

    var visiblePullRequestContentView: NSView? {
        pullRequestWindows.values.first(where: \.isVisible)?.contentView
    }

    private var mode: WindowMode {
        assembly.settings.values.windowMode
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
            let dropView = FileDropView(
                accepts: { VideoCompressionPolicy.isVideo($0.path) },
                onTarget: { [weak self] isTargeted in
                    guard let self else { return }
                    statusItem.button?.highlight(isTargeted || panel.isVisible)
                },
                onDrop: { [weak self] urls in
                    guard let self else { return }
                    show()
                    assembly.appActions.compressVideos(urls.map(\.path))
                },
                onClick: { [weak self] in
                    guard let self else { return }
                    statusItemClicked()
                }
            )
            dropView.frame = button.bounds
            button.addSubview(dropView)
        }
        updateStatusLabel()
        observeLayout()
        observeActivation()
        assembly.settings.onWindowModeChange = { [weak self] mode in
            self?.applyWindowMode(mode)
        }
        assembly.settings.applyDockIcon()
        installMainMenu()
        assembly.usage.startPolling()
        assembly.openPullRequests.startPolling()
        assembly.inbox.startPolling()
        assembly.ciAutoRerun.startPolling()
        assembly.ciWatch.startPolling()
        assembly.ciBranchRuns.startPolling()
        assembly.updates.onInstalling = { NSApp.terminate(nil) }
        assembly.updates.start()
        observeNotificationClicks()
        Task { [assembly] in
            await assembly.config.reload()
            await assembly.mockSets.load()
            assembly.mockServer.restoreServers()
        }
        resignObserver = NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.closePanel()
            }
        }
        if mode == .window, layout.isWindowOpen {
            showWindow()
        }
    }

    private func observeNotificationClicks() {
        Task { [weak self, assembly] in
            for await target in assembly.notifier.activations() {
                guard let self else { return }
                show()
                if let target {
                    assembly.appActions.open(target)
                } else {
                    assembly.appActions.openNotifications()
                }
            }
        }
    }

    package func toggle() {
        switch mode {
        case .panel: showPinnedOrPanel()
        case .window: toggleWindow()
        }
    }

    package func show() {
        switch mode {
        case .panel:
            guard panel.isVisible == false else { return }
            showPinnedOrPanel()
        case .window:
            showWindow()
        }
    }

    func togglePanel() {
        if panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func showPinnedOrPanel() {
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

    func showWindow() {
        closePanel()
        pinnedWindow?.close()
        let window = mainWindow ?? makeMainWindow()
        if mainWindow == nil {
            mainWindow = window
        } else {
            layout.openCount += 1
        }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        if window.isVisible, window.isOnActiveSpace == false {
            window.orderOut(nil)
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        layout.isWindowOpen = true
        updatePanelShown()
    }

    func hideWindow() {
        guard let mainWindow, mainWindow.isVisible else { return }
        mainWindow.orderOut(nil)
        layout.isWindowOpen = false
        updatePanelShown()
        if pullRequestWindows.values.contains(where: \.isVisible) == false {
            NSApp.hide(nil)
        }
    }

    private func toggleWindow() {
        if let mainWindow, NSApp.isActive, mainWindow.isKeyWindow, mainWindow.isOnActiveSpace {
            hideWindow()
        } else {
            showWindow()
        }
    }

    private func applyWindowMode(_ mode: WindowMode) {
        installMainMenu()
        switch mode {
        case .panel:
            mainWindow?.orderOut(nil)
            layout.isWindowOpen = false
            showPanel()
        case .window:
            showWindow()
        }
    }

    package func showPullRequestWindow(_ summary: PullRequestSummary) {
        closePanel()
        let window: NSWindow
        if let existing = pullRequestWindows[summary.id], existing.isVisible {
            window = existing
        } else {
            window = makePullRequestWindow(summary)
            pullRequestWindows[summary.id] = window
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func statusItemClicked() {
        guard NSApp.currentEvent?.type == .rightMouseDown else {
            toggle()
            return
        }
        closePanel()
        statusItem.menu = statusMenu()
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func statusMenu() -> NSMenu {
        let menu = NSMenu()
        let items = StatusMenuMapper.items(
            projects: assembly.session.projects,
            selectedID: assembly.session.selectedProjectID,
            isKeepAwakeOn: assembly.keepAwake.isActive
        )
        for item in items {
            menu.addItem(menuItem(for: item))
        }
        return menu
    }

    private func menuItem(for item: StatusMenuItem) -> NSMenuItem {
        switch item {
        case .show:
            return menuItem("Show DevHub", action: #selector(menuShow))
        case .projectsHeader:
            return NSMenuItem.sectionHeader(title: "Projects")
        case let .project(id, title, isSelected):
            let entry = menuItem(title, action: #selector(menuSelectProject(_:)))
            entry.representedObject = id
            entry.state = isSelected ? .on : .off
            return entry
        case .keepAwake(let isOn):
            let entry = menuItem("Keep Mac Awake", action: #selector(menuKeepAwake))
            entry.state = isOn ? .on : .off
            return entry
        case .checkForUpdates:
            return menuItem("Check for Updates", action: #selector(menuCheckForUpdates))
        case .settings:
            return menuItem("Settings…", key: ",", action: #selector(menuSettings))
        case .quit:
            return menuItem("Quit DevHub", key: "q", action: #selector(menuQuit))
        case .separator:
            return .separator()
        }
    }

    private func menuItem(_ title: String, key: String = "", action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func menuShow() {
        show()
    }

    @objc private func menuSelectProject(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? Project.ID else { return }
        assembly.session.selectedProjectID = id
        show()
    }

    @objc private func menuKeepAwake() {
        assembly.keepAwake.toggle()
    }

    @objc private func menuQuit() {
        NSApp.terminate(nil)
    }

    // MARK: NSWindowDelegate

    package func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard sender === mainWindow else { return true }
        hideWindow()
        return false
    }

    package func windowDidMiniaturize(_ notification: Notification) {
        updatePanelShown()
    }

    package func windowDidDeminiaturize(_ notification: Notification) {
        updatePanelShown()
    }

    @objc private func menuSettings() {
        show()
        assembly.appActions.openSettings()
    }

    @objc private func menuCheckForUpdates() {
        show()
        Task { [assembly] in
            await assembly.updates.checkNow()
        }
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
        updatePanelShown()
    }

    private func closePanel() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        statusItem.button?.highlight(false)
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
        updatePanelShown()
    }

    private func pinnedWindowWillClose() {
        assembly.notifier.panelShown(panel.isVisible)
    }

    private func updatePanelShown() {
        let isMainShown = mainWindow?.isVisible == true && mainWindow?.isMiniaturized == false && NSApp.isActive
        assembly.notifier.panelShown(panel.isVisible || isPinnedVisible || isMainShown)
    }

    private func installMainMenu() {
        guard mode == .window else { return }
        NSApp.mainMenu = MainMenuBuilder.build(target: self, settings: #selector(menuSettings), checkForUpdates: #selector(menuCheckForUpdates))
    }

    private func observeActivation() {
        let names: [Notification.Name] = [NSApplication.didBecomeActiveNotification, NSApplication.didResignActiveNotification]
        activationObservers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                let becameActive = notification.name == NSApplication.didBecomeActiveNotification
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if becameActive {
                        installMainMenu()
                    }
                    updatePanelShown()
                }
            }
        }
    }

    private func installClickMonitor() {
        guard clickMonitor == nil else { return }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            Task { @MainActor in
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
        updatePanelShown()
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
        pinnedCloseObserver = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.pinnedWindowWillClose()
            }
        }
        return window
    }

    private func makeMainWindow() -> MainWindow {
        let window = MainWindow()
        window.delegate = self
        window.contentViewController = hostingController(isPinned: true)
        if window.setFrameUsingName(WindowLayout.mainAutosaveName) == false,
           window.setFrameUsingName(WindowLayout.pinnedAutosaveName) == false {
            window.setContentSize(layout.size)
            window.center()
        }
        window.setFrameAutosaveName(WindowLayout.mainAutosaveName)
        return window
    }

    private func makePullRequestWindow(_ summary: PullRequestSummary) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: NSSize(width: 1_120, height: 760)),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(assembly.codeHostRemote.words.reference(summary.iid)) \(summary.title)"
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .aqua)
        window.contentMinSize = NSSize(width: 1_000, height: 560)
        window.collectionBehavior.insert(.moveToActiveSpace)
        let root = PullRequestWindowView(summary: summary)
            .inject(assembly)
            .colorScheme(.light)
        window.contentViewController = NSHostingController(rootView: root)
        if window.setFrameUsingName(WindowLayout.pullRequestAutosaveName) == false {
            window.center()
        }
        window.setFrameAutosaveName(WindowLayout.pullRequestAutosaveName)
        return window
    }

    private func hostingController(isPinned: Bool) -> NSViewController {
        let root = RootView()
            .inject(assembly)
            .environment(\.isPinnedWindow, isPinned)
            .environment(\.togglePin, { [weak self] in self?.togglePin() })
            .environment(\.openPullRequestWindow, { [weak self] in self?.showPullRequestWindow($0) })
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
            let showsCI = settings.values.showCIStateInMenuBar
            let failedRequests = showsCI ? assembly.openPullRequests.failedOwnRequestIDs : []
            let onHold = showsCI ? assembly.ciWatch.onHoldJobNames : [:]
            let state = StatusItemState.state(
                isBuilding: assembly.build.isRunning,
                hasUnseenFailure: assembly.notifier.hasUnseenFailure,
                isCIFailed: failedRequests.isEmpty == false,
                isCIWaiting: onHold.isEmpty == false,
                isKeepingAwake: assembly.keepAwake.isActive
            )
            statusItem.button?.image = StatusItemImage.image(for: state)
            statusItem.button?.toolTip = StatusItemHint.text(for: state, failedRequests: failedRequests, onHold: onHold, words: assembly.codeHostRemote.words)
            statusItem.button?.title = StatusItemTitle.text(
                usage: settings.values.showUsageInMenuBar ? usage.menuBarPercentText : nil,
                reviewCount: settings.values.showReviewCountInMenuBar ? assembly.openPullRequests.reviewCount : nil,
                words: assembly.codeHostRemote.words
            )
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                self?.updateStatusLabel()
            }
        }
    }
}
