import SwiftUI

struct RunBarResult: View {
    @Environment(BuildStore.self) private var build

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch build.phase {
            case .idle:
                EmptyView()
            case let .running(text):
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .frame(width: 80)
                    Text("\(build.activeMode?.title ?? "Build"): \(text)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            case let .succeeded(text):
                line(text, systemImage: "checkmark.circle.fill", tint: .green, showsLog: false)
            case let .failed(failure):
                line(failure.message, systemImage: "xmark.octagon.fill", tint: .red, showsLog: failure.logPath != nil)
            }
            if let notice = build.attachNotice {
                RunBarAttachNotice(notice: notice)
            }
        }
    }

    private func line(_ text: String, systemImage: String, tint: Tint, showsLog: Bool) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(tint.color)
            Text(text)
                .font(.caption)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            if showsLog {
                Button("Show log") { build.showLog() }
                    .controlSize(.small)
                    .fixedSize()
                    .hint("Open the full build log in Console")
            }
            IconButton(systemImage: "xmark", help: "Dismiss") { build.dismissResult() }
        }
        .padding(8)
        .background(tint.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    RunBarResult()
        .padding()
        .previewEnvironment()
}
