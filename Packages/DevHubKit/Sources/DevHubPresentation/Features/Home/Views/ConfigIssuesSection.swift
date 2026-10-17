import SwiftUI
import DevHubDomain
import DevHubUI

struct ConfigIssuesSection: View {
    @Environment(ConfigStore.self) private var config

    var body: some View {
        let issues = config.issues
        if issues.isEmpty == false {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Tint.red.color)
                    Text(ConfigIssueRowMapper.title(count: issues.count))
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Reload") {
                        Task { await config.reload() }
                    }
                    .controlSize(.small)
                    .fixedSize()
                }
                ForEach(issues.map(ConfigIssueRowMapper.model(for:))) { row in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(row.location)
                            .font(.caption.monospaced().weight(.semibold))
                        Text(row.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tint.red.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

#Preview {
    ConfigIssuesSection()
        .padding()
        .previewEnvironment()
}
