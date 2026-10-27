import SwiftUI
import DevHubUI

struct ProjectShortcutModifier: ViewModifier {
    let digit: Character?

    func body(content: Content) -> some View {
        if let digit {
            content.keyboardShortcut(KeyEquivalent(digit), modifiers: [.control, .command])
        } else {
            content
        }
    }
}
