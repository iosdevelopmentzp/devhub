import SwiftUI
import DevHubDomain
import DevHubUI

struct UtilsView: View {
    @Environment(UtilsStore.self) private var utils

    var body: some View {
        @Bindable var utils = utils
        VStack(spacing: 0) {
            ToolbarBar(verticalPadding: 7) {
                HStack {
                    Picker("Tool", selection: $utils.selection) {
                        ForEach(UtilityID.allCases, id: \.self) { tool in
                            Label(tool.title, systemImage: tool.systemImage)
                                .tag(tool)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    Spacer()
                    TabSearchField()
                }
            }
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.surface)
    }

    @ViewBuilder
    private var content: some View {
        switch utils.selection {
        case .compressVideo:
            VideoCompressionView()
        }
    }
}

#Preview {
    UtilsView()
        .previewEnvironment()
}
