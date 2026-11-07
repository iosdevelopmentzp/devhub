import SwiftUI
import DevHubDomain
import DevHubUI

extension View {
    func tabPlacementMenu(for tab: TabID, isEnabled: Bool) -> some View {
        modifier(TabPlacementMenuModifier(tab: tab, isEnabled: isEnabled))
    }
}

private struct TabPlacementMenuModifier: ViewModifier {
    let tab: TabID
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.contextMenu { TabPlacementMenu(tab: tab) }
        } else {
            content
        }
    }
}
