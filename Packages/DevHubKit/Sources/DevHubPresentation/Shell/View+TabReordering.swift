import SwiftUI
import UniformTypeIdentifiers
import DevHubDomain
import DevHubUI

extension View {
    func tabReordering(_ tab: TabID, navigator: Navigator) -> some View {
        modifier(TabReorderingModifier(tab: tab, navigator: navigator))
    }
}

private struct TabReorderingModifier: ViewModifier {
    let tab: TabID
    let navigator: Navigator

    func body(content: Content) -> some View {
        content
            .onDrag {
                navigator.draggedTab = tab
                return NSItemProvider(object: tab.rawValue as NSString)
            }
            .onDrop(of: [.plainText], delegate: TabDropDelegate(target: tab, navigator: navigator))
    }
}
