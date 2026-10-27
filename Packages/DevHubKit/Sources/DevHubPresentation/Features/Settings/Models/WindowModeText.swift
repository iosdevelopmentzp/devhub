import Foundation
import DevHubDomain

enum WindowModeText {
    static func title(for mode: WindowMode) -> String {
        switch mode {
        case .panel: "Menu bar panel"
        case .window: "Normal window"
        }
    }

    static func hint(for mode: WindowMode) -> String {
        switch mode {
        case .panel: "DevHub opens under the menu bar icon and closes when you click outside it. The pin button keeps it open in a floating window."
        case .window: "DevHub has one window with a Dock icon and a menu bar. The close button hides it. The menu bar icon and the shortcut bring it to the current desktop."
        }
    }

    static func shortcutHint(for mode: WindowMode) -> String {
        switch mode {
        case .panel: "A global key combination that opens the menu bar panel, or brings the pinned window to the front"
        case .window: "A global key combination that shows the DevHub window on the current desktop, or hides it when it is in front"
        }
    }
}
