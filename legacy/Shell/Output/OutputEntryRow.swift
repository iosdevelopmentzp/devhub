import SwiftUI

struct OutputEntryRow: View {
    @Environment(Toaster.self) private var toaster

    let entry: CommandEntry

    @State private var showsAllLines = false

    private static let collapsedLineCount = 8

    private var tint: Tint {
        if entry.isRunning {
            return .blue
        }
        if entry.isCancelled {
            return .orange
        }
        return entry.isFailure ? .red : .green
    }

    private var visibleLines: [String] {
        showsAllLines ? entry.lines : Array(entry.lines.suffix(Self.collapsedLineCount))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            if let cwd = entry.cwd {
                Text(cwd)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .copyOnClick(cwd, label: "folder")
            }
            if let notice = entry.hiddenOutputNotice {
                Text(notice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                lines
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        HStack(spacing: 8) {
            if entry.isRunning {
                ProgressView()
                    .controlSize(.mini)
            } else {
                StatusDot(color: tint)
            }
            Text("$ \(entry.command)")
                .font(.caption.monospaced().weight(.semibold))
                .lineLimit(1)
                .truncationMode(.middle)
                .hintWhenTruncated(entry.command)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let exit = entry.exitText {
                Tag(exit, tint: entry.isFailure ? .red : (entry.isCancelled ? .orange : .gray))
            }
            Text(entry.durationText ?? "running")
                .font(.caption2)
                .foregroundStyle(.secondary)
            IconButton(systemImage: "doc.on.doc", help: "Copy this command and its output") {
                toaster.copy(entry.plainText, label: "command")
            }
        }
    }

    @ViewBuilder
    private var lines: some View {
        if entry.lines.isEmpty == false {
            VStack(alignment: .leading, spacing: 1) {
                ForEach(visibleLines.indices, id: \.self) { index in
                    Text(visibleLines[index])
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if entry.lines.count > Self.collapsedLineCount {
                Button(showsAllLines ? "Show fewer lines" : "Show all \(entry.lines.count) lines") {
                    showsAllLines.toggle()
                }
                .buttonStyle(.link)
                .font(.caption2)
            }
        }
    }
}

#Preview {
    OutputEntryRow(entry: CommandEntry(id: UUID(), command: "git --version", cwd: "/tmp", kind: .action, startedAt: Date(), finishedAt: Date(), exitCode: 0, lines: ["git version 2.50.0"]))
        .previewEnvironment()
}
