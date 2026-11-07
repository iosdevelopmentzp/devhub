import SwiftUI
import DevHubDomain
import DevHubUI

struct UtilityTabView: View {
    let id: UtilityID

    var body: some View {
        VStack(spacing: 0) {
            ToolbarBar {
                HStack {
                    Text(id.title)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    TabSearchField()
                }
            }
            Divider()
            UtilityContent(id: id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.surface)
    }
}

#Preview {
    UtilityTabView(id: .compressVideo)
        .previewEnvironment()
}
