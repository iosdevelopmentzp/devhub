import AppKit
import Observation
import ServiceManagement
import DevHubDomain
import DevHubUI

@MainActor
@Observable
package final class SettingsStore {
    package var values: AppSettings {
        didSet {
            guard values != oldValue else { return }
            store.encode(values, forKey: PreferenceKeys.settings)
            if values.showDockIcon != oldValue.showDockIcon {
                applyDockIcon()
            }
            if values.globalShortcut != oldValue.globalShortcut {
                onShortcutChange?(values.globalShortcut)
            }
        }
    }
    private(set) var launchesAtLogin = SMAppService.mainApp.status == .enabled
    private(set) var loginItemError: String?

    @ObservationIgnored package var onShortcutChange: ((GlobalShortcut) -> Void)?
    @ObservationIgnored private let store: any KeyValueStore

    init(values: AppSettings, store: any KeyValueStore) {
        self.values = values
        self.store = store
    }

    package func applyDockIcon() {
        NSApp.setActivationPolicy(values.showDockIcon ? .regular : .accessory)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemError = nil
        } catch {
            loginItemError = error.localizedDescription
        }
        launchesAtLogin = SMAppService.mainApp.status == .enabled
        if enabled, SMAppService.mainApp.status == .requiresApproval {
            loginItemError = "macOS needs your approval: System Settings → General → Login Items."
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}
