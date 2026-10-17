import SwiftUI
import DevHubDomain
import DevHubUI

struct ConfigActionMenuItems: View {
    let items: [ConfigActionItemModel]
    let onRun: (ConfigActionItemModel.ID) -> Void

    var body: some View {
        if items.isEmpty == false {
            Divider()
            ForEach(items) { item in
                Button(item.title, systemImage: item.systemImage) {
                    onRun(item.id)
                }
                .disabled(item.isEnabled == false)
            }
        }
    }
}

#Preview {
    Menu("Actions") {
        ConfigActionMenuItems(items: [.preview], onRun: { _ in })
    }
    .padding()
}
