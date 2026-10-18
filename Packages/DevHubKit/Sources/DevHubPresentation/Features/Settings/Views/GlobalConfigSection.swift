import SwiftUI
import DevHubDomain
import DevHubUI

struct GlobalConfigSection: View {
    @Environment(ConfigStore.self) private var config
    @Environment(AppActions.self) private var appActions

    var body: some View {
        let layer = config.globalLayer
        Section {
            HStack {
                Text(layer.directory.abbreviatingHome)
                    .font(.callout.monospaced())
                    .foregroundStyle(layer.exists ? .primary : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .copyOnClick(layer.directory, label: layer.directory.abbreviatingHome)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if layer.exists {
                    Button("Reveal", systemImage: "folder") {
                        appActions.openInFinder(path: layer.directory)
                    }
                    .fixedSize()
                } else {
                    Text("not created")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Global config folder")
        } footer: {
            Text("Actions, scripts and tabs in this folder appear in every project. An item with the same id in a project folder wins.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    Form {
        GlobalConfigSection()
    }
    .formStyle(.grouped)
    .previewEnvironment()
}
