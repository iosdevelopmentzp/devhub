import SwiftUI
import DevHubDomain
import DevHubUI

struct DoctorRow<Trailing: View>: View {
    @Environment(Toaster.self) private var toaster

    let model: DoctorRowModel
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: model.icon)
                .foregroundStyle(model.stateTint.color)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.name)
                        .font(.callout.monospaced().weight(.medium))
                    Text(model.stateText)
                        .font(.caption)
                        .foregroundStyle(model.stateTint.color)
                }
                Text(model.purpose)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let path = model.path {
                    Text(path)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .copyOnClick(path, label: "path")
                }
            }
            Spacer(minLength: 8)
            if let command = model.installCommand {
                Button("Copy Install Command", systemImage: "doc.on.doc") {
                    toaster.copy(command, label: command)
                }
                .controlSize(.small)
                .fixedSize()
                .hint(command)
            }
            trailing()
        }
    }
}

#Preview {
    DoctorRow(model: .preview) {}
        .padding()
        .previewEnvironment()
}
