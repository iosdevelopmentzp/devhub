import Carbon.HIToolbox
import Foundation

extension Notification.Name {
    nonisolated static let globalHotKeyPressed = Notification.Name("DevHub.globalHotKeyPressed")
}

private nonisolated func globalHotKeyHandler(
    _ call: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    NotificationCenter.default.post(name: .globalHotKeyPressed, object: nil)
    return noErr
}

final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    func register(_ choice: HotKeyChoice) {
        unregister()
        guard let combination = Self.combination(for: choice) else { return }
        installHandler()
        let identifier = EventHotKeyID(signature: OSType(0x4456_4842), id: 1)
        RegisterEventHotKey(combination.keyCode, combination.modifiers, identifier, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        guard let hotKeyRef else { return }
        UnregisterEventHotKey(hotKeyRef)
        self.hotKeyRef = nil
    }

    private func installHandler() {
        guard handlerRef == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), globalHotKeyHandler, 1, &spec, nil, &handlerRef)
    }

    private static func combination(for choice: HotKeyChoice) -> (keyCode: UInt32, modifiers: UInt32)? {
        switch choice {
        case .optionCommandD: (UInt32(kVK_ANSI_D), UInt32(optionKey | cmdKey))
        case .controlOptionSpace: (UInt32(kVK_Space), UInt32(controlKey | optionKey))
        case .controlOptionD: (UInt32(kVK_ANSI_D), UInt32(controlKey | optionKey))
        case .off: nil
        }
    }
}
