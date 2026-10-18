import SwiftUI
import DevHubDomain
import DevHubUI

struct ProjectSettingsRow: View {
    let model: ProjectSettingsRowModel
    @Binding var scheme: String
    @Binding var bundleID: String
    let onRedetect: () -> Void
    let onRemove: () -> Void

    @State private var isConfirmingRemove = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: model.icon)
                    .foregroundStyle(model.iconTint.color)
                    .hint(model.iconHint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(model.name)
                    Text(model.path)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .copyOnClick(model.path, label: model.path)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let tag = model.deviceToolsTag {
                    ModelTag(model: tag)
                }
                IconButton(systemImage: "arrow.triangle.2.circlepath", help: "Find the scheme and bundle ID again in the project files") {
                    onRedetect()
                }
                IconButton(systemImage: "minus.circle", help: model.removeHint, tint: .red) {
                    isConfirmingRemove = true
                }
                .disabled(model.canRemove == false)
            }
            HStack(spacing: 8) {
                TextField("Scheme", text: $scheme)
                    .frame(width: 160)
                    .hint("The scheme Build & Run starts with. The run bar can switch it.")
                TextField("Bundle ID", text: $bundleID)
                    .font(.callout.monospaced())
                    .hint("Used to uninstall and launch the app on simulators")
            }
            .textFieldStyle(.roundedBorder)
            .controlSize(.small)
            if isConfirmingRemove {
                InlineConfirmation(
                    model.removeQuestion,
                    confirmTitle: "Remove",
                    confirmRole: .destructive,
                    systemImage: nil,
                    onCancel: { isConfirmingRemove = false },
                    onConfirm: {
                        isConfirmingRemove = false
                        onRemove()
                    }
                )
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    Form {
        ProjectSettingsRow(
            model: .preview,
            scheme: .constant("ExampleApp"),
            bundleID: .constant("com.example.app"),
            onRedetect: {},
            onRemove: {}
        )
    }
    .formStyle(.grouped)
    .previewEnvironment()
}
