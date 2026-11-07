import SwiftUI
import DevHubDomain
import DevHubUI

struct TabPlacementMenu: View {
    @Environment(Navigator.self) private var navigator

    let tab: TabID

    var body: some View {
        switch navigator.placement(of: tab) {
        case .bar:
            Button("Move to Utils", systemImage: "hammer") {
                navigator.move(tab, to: .utils)
            }
        case .utils:
            Button("Show in Tab Bar", systemImage: "rectangle.topthird.inset.filled") {
                navigator.move(tab, to: .bar)
            }
        }
    }
}

#Preview {
    Menu("Tab") {
        TabPlacementMenu(tab: .feature(.logs))
    }
    .padding()
    .previewEnvironment()
}
