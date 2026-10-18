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
            if let tag = model.productionTag {
                ModelTag(model: tag)
            }
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
        let selection = Binding(get: { model.selectedID }, set: { onSelect($0) })
        if model.usesSegments {
            Picker("Launch profile", selection: selection) {
                ForEach(model.options) { option in
                    optionLabel(option).tag(option.id)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        } else {
            Picker("Launch profile", selection: selection) {
                ForEach(model.options) { option in
                    optionLabel(option).tag(option.id)
                }
            }
            .labelsHidden()
        }
    }

    @ViewBuilder
    private func optionLabel(_ option: LaunchProfileModel.Option) -> some View {
        if option.isProduction {
            Label(option.title, systemImage: "exclamationmark.triangle.fill")
        } else {
            Text(option.title)
        }
    }
}

#Preview {
    LaunchProfilePicker(model: .preview, onSelect: { _ in })
        .padding()
}
