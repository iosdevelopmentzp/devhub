import SwiftUI
import DevHubDomain
import DevHubUI

struct LaunchProfilePicker: View {
    let model: LaunchProfileModel
    let onSelect: (LaunchProfile.ID) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("Profile")
                .font(.caption)
                .foregroundStyle(.secondary)
            picker
                .fixedSize()
            Text(model.summary)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .hint("\(model.details)\n\nOnly launches from DevHub get these values. A launch from Xcode or the home screen does not.")
            Spacer(minLength: 0)
        }
        .controlSize(.small)
    }

    @ViewBuilder
    private var picker: some View {
        let selection = Binding(get: { model.selectedID }, set: onSelect)
        if model.usesSegments {
            Picker("Launch profile", selection: selection) {
                ForEach(model.options) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        } else {
            Picker("Launch profile", selection: selection) {
                ForEach(model.options) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .labelsHidden()
        }
    }
}

#Preview {
    LaunchProfilePicker(model: .preview, onSelect: { _ in })
        .padding()
}
