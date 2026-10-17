import AppKit
import Observation

extension AppWindows {
    func observeSystem() {
        resignObserver = NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.closePanel()
            }
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.fitVisiblePanel()
            }
        }
        NotificationCenter.default.addObserver(forName: .globalHotKeyPressed, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.showPinnedOrPanel()
            }
        }
        observeLayout()
    }

    func applySettings() {
        hotKey.register(settings.hotKey)
        NSApp.setActivationPolicy(settings.showDockIcon ? .regular : .accessory)
        withObservationTracking {
            _ = settings.hotKey
            _ = settings.showDockIcon
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self?.applySettings()
                }
            }
        }
    }

    func installClickMonitor() {
        guard clickMonitor == nil else { return }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self?.closePanel()
                }
            }
        }
    }

    func removeClickMonitor() {
        guard let clickMonitor else { return }
        NSEvent.removeMonitor(clickMonitor)
        self.clickMonitor = nil
    }

    private func observeLayout() {
        withObservationTracking {
            _ = layout.size
            _ = layout.panelTopLeft
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self?.fitVisiblePanel()
                    self?.observeLayout()
                }
            }
        }
    }

    private func fitVisiblePanel() {
        guard isPanelVisible else { return }
        fitPanel()
    }
}
