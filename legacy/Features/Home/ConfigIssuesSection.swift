import SwiftUI

struct ConfigIssuesSection: View {
    @Environment(ConfigStore.self) private var config
    @Environment(HomeStore.self) private var store

    var body: some View {
        if config.issues.isEmpty == false {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Tint.red.color)
                    Text(config.issues.count == 1 ? "1 config problem" : "\(config.issues.count) config problems")
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Reload") { store.reloadConfig() }
                        .controlSize(.small)
                }
                ForEach(config.issues) { issue in
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(issue.layer.title): \(issue.fileName)")
                            .font(.caption.monospaced().weight(.semibold))
                        Text(issue.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tint.red.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    ConfigIssuesSection()
        .padding()
        .previewEnvironment()
}
