import SwiftUI
import DevHubDomain
import DevHubUI

struct LaunchIdentityControls: View {
    let model: LaunchIdentityModel
    @Binding var environment: String
    @Binding var deviceID: String
    @Binding var alias: String
    let onForget: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                FieldLabel("Environment")
                Picker("Environment", selection: $environment) {
                    Text("keep").tag("")
                    ForEach(model.environments, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 240)
                .hint("keep = do not touch the value stored in the app")
                if let productionTag = model.productionTag {
                    ModelTag(model: productionTag)
                }
            }
            HStack(spacing: 8) {
                FieldLabel("Device ID")
                TextField("empty = the simulator's own ID", text: $deviceID)
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
                    deviceID = "devhub-\(UUID().uuidString.prefix(8).lowercased())"
                }
                .hint("A random ID: the backend registers a new account on it")
                Button("Own", systemImage: "iphone") {
                    deviceID = ""
                }
                .hint("No override: the app uses its own keychain ID and forgets the ID kept from DevHub")
            }
            HStack(spacing: 8) {
                FieldLabel("Alias")
                TextField(model.aliasPlaceholder, text: $alias)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .frame(width: 260)
                    .disabled(model.canEditAlias == false)
                    .hint("A name for the device ID in the field, or for the simulator's current ID when the field is empty. DevHub shows it next to the ID.")
            }
        }
        .controlSize(.small)
    }
}

#Preview {
    LaunchIdentityControls(
        model: .preview,
        environment: .constant(""),
        deviceID: .constant(""),
        alias: .constant(""),
        onForget: { _ in }
    )
    .padding()
}
