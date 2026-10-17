import SwiftUI
import DevHubDomain
import DevHubUI

struct ScriptHintCard: View {
    private let example = """
    #!/bin/zsh
    # title: Clean DerivedData
    # subtitle: Removes DerivedData for this project
    # icon: trash
    """

    var body: some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Add your own", systemImage: "lightbulb")
                    .font(.callout.weight(.medium))
                Text("Any executable file in the scripts folder becomes a row here. The header lines set the title, subtitle and icon.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(example)
                    .font(.caption.monospaced())
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.base, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .textSelection(.enabled)
            }
        }
    }
}
