import SwiftUI
import DevHubDomain
import DevHubUI

struct LaunchIdentityControls: View {
    let model: LaunchIdentityModel
    @Binding var deviceID: String
    @Binding var alias: String
    let onForget: (String) -> Void
    let newID: () -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                FieldLabel("ID")
                TextField("empty = the app's own ID", text: $deviceID)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption.monospaced())
                    .frame(width: 260)
                Menu {
                    ForEach(model.savedDeviceIDs) { saved in
                        Button(saved.title) { deviceID = saved.id }
                    }
                    if model.savedDeviceIDs.isEmpty == false {
                        Divider()
                        Menu("Forget") {
                            ForEach(model.savedDeviceIDs) { saved in
                                Button(saved.title) { onForget(saved.id) }
                            }
                        }
                    }
                } label: {
                    Label("Saved", systemImage: "list.bullet")
                }
                .fixedSize()
                Button("New", systemImage: "dice") {
                    deviceID = newID()
                }
                .hint("A new random ID for the next launch")
                Button("Own", systemImage: "iphone") {
                    deviceID = ""
                }
                .hint("No ID from DevHub: the app uses its own")
            }
            HStack(spacing: 8) {
                FieldLabel("Alias")
                TextField(model.aliasPlaceholder, text: $alias)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .frame(width: 260)
                    .disabled(model.canEditAlias == false)
                    .hint("A name for the ID in the field, or for the current ID when the field is empty. DevHub shows it next to the ID.")
            }
        }
        .controlSize(.small)
    }
}

#Preview {
    LaunchIdentityControls(
        model: .preview,
        deviceID: .constant(""),
        alias: .constant(""),
        onForget: { _ in },
        newID: { "devhub-1a2b3c4d" }
    )
    .padding()
}
