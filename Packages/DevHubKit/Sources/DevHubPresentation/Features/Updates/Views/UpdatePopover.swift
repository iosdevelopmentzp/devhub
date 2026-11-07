import SwiftUI
import DevHubUI

struct UpdatePopover: View {
    let model: UpdateIndicatorModel
    let log: String?
    let onAction: () -> Void

    static let width: CGFloat = 380
    static let logHeight: CGFloat = 220

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.title)
                .font(.callout.weight(.semibold))
            if model.commits.isEmpty == false {
                commitList
            }
            if let failure = model.failure {
                Text(failure)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if model.showsLog {
                logView
            }
            if let title = model.actionTitle {
                HStack {
                    Spacer()
                    Button(title, action: onAction)
                        .controlSize(.small)
                        .keyboardShortcut(.defaultAction)
                        .fixedSize()
                }
            }
        }
        .padding(12)
        .frame(width: Self.width, alignment: .leading)
    }

    private var commitList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(model.commits) { commit in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(commit.hash)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text(commit.subject)
                        .font(.caption)
                        .lineLimit(2)
                }
            }
        }
    }

    private var logView: some View {
        ScrollView {
            Text(log ?? "No log yet.")
                .font(.caption2.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
        }
        .frame(height: Self.logHeight)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Theme.border))
    }
}

#Preview("Available") {
    UpdatePopover(model: .preview, log: nil) {}
}

#Preview("Failed") {
    UpdatePopover(model: .previewFailed, log: "xcodebuild: error: Build failed\n") {}
}
