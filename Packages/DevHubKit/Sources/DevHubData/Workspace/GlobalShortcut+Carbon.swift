import Carbon.HIToolbox
import DevHubDomain

extension GlobalShortcut {

    var carbonKey: (code: UInt32, modifiers: UInt32)? {
        switch self {
        case .off: nil
        case .optionCommandD: (UInt32(kVK_ANSI_D), UInt32(optionKey | cmdKey))
        case .controlOptionSpace: (UInt32(kVK_Space), UInt32(controlKey | optionKey))
        case .controlOptionD: (UInt32(kVK_ANSI_D), UInt32(controlKey | optionKey))
        }
    }
}
