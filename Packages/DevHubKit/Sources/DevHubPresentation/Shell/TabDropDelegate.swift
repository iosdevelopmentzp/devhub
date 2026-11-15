import SwiftUI
import DevHubDomain
import DevHubUI

struct TabDropDelegate: DropDelegate {
    let target: TabID
    let navigator: Navigator

    func validateDrop(info: DropInfo) -> Bool {
        navigator.draggedTab != nil
    }

    func dropEntered(info: DropInfo) {
        guard let dragged = navigator.draggedTab, dragged != target else { return }
        withAnimation(.snappy(duration: 0.18)) {
            navigator.reorder(dragged, to: target)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        navigator.draggedTab = nil
        return true
    }
}
