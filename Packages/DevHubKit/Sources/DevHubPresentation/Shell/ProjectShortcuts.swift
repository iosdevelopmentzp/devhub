import SwiftUI
import DevHubDomain
import DevHubUI

struct ProjectShortcuts: View {
    let items: [ProjectSwitchItem]
    let onSelect: (Project.ID) -> Void

    var body: some View {
        ZStack {
            ForEach(items.filter { $0.digit != nil }) { item in
                if let digit = item.digit {
                    Button("") { onSelect(item.id) }
                        .keyboardShortcut(KeyEquivalent(digit), modifiers: [.control, .command])
                }
            }
        }
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
