import AppKit
import Carbon.HIToolbox
import DevHubDomain

@MainActor
package final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var observer: NSObjectProtocol?
    private let action: () -> Void

    package init(action: @escaping () -> Void) {
        self.action = action
        installHandler()
        observer = NotificationCenter.default.addObserver(forName: .devHubHotKeyPressed, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.action()
            }
        }
    }

    package func register(_ shortcut: GlobalShortcut) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        guard let key = shortcut.carbonKey else { return }
        let id = EventHotKeyID(signature: OSType(0x4456_4842), id: 1)
        RegisterEventHotKey(key.code, key.modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    private func installHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), hotKeyPressed, 1, &spec, nil, nil)
    }
}

private nonisolated func hotKeyPressed(_ call: EventHandlerCallRef?, _ event: EventRef?, _ userData: UnsafeMutableRawPointer?) -> OSStatus {
    DispatchQueue.main.async {
        NotificationCenter.default.post(name: .devHubHotKeyPressed, object: nil)
    }
    return noErr
}
