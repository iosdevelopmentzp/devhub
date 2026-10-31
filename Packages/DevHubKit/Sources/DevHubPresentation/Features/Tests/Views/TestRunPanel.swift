import SwiftUI
import DevHubDomain
import DevHubUI

struct TestRunPanel: View {
    let model: TestRunPanelModel
    let onCancel: () -> Void
    let onDismiss: () -> Void
    let onRunAgain: () -> Void
    let onOpenFailure: (TestFailureRowModel) -> Void
    let onOpenIssue: (BuildIssueRowModel) -> Void
    let onOpenResults: (String) -> Void
    let onFix: (AIProvider) -> Void

    @State private var showsAllFailures = false

    private static let collapsedCount = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if let step = model.step {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                    Text(step)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            if let title = model.failuresTitle {
                failureList(title)
            }
            if let title = model.issuesTitle {
                BuildIssuesList(title: title, rows: model.issues, onOpen: onOpenIssue, onFix: nil)
            }
            if model.isRunning == false {
                footer
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.base)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Theme.border)
                )
        )
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: model.icon)
                .font(.caption)
                .foregroundStyle(model.tint.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                if let detail = model.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 4)
            if model.isRunning {
                IconButton(systemImage: "stop.fill", help: "Stop the tests", tint: .red, action: onCancel)
            } else {
                IconButton(systemImage: "xmark", help: "Hide the test result", action: onDismiss)
            }
        }
    }

    private func failureList(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if model.failures.count > Self.collapsedCount {
                    Button(showsAllFailures ? "Show fewer" : "Show all \(model.failures.count)") {
                        showsAllFailures.toggle()
                    }
                    .buttonStyle(LinkButtonStyle(.accent))
                }
            }
            ForEach(showsAllFailures ? model.failures : Array(model.failures.prefix(Self.collapsedCount))) { row in
                Button {
                    onOpenFailure(row)
                } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Tint.red.color)
                            if let test = row.test {
                                Text(test)
                                    .font(.caption.weight(.medium))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            if let location = row.location {
                                Text(location)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        Text(row.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 18)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(row.path == nil)
                .hint(row.hint)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Button("Run Again", systemImage: "arrow.clockwise", action: onRunAgain)
                .buttonStyle(LinkButtonStyle(.accent))
                .disabled(model.canRunAgain == false)
            if model.canFix {
                AIProviderMenu(title: "Fix with AI", systemImage: "sparkles", hint: "Writes the failed tests and the compiler errors into a prompt file and starts the tool in the terminal, inside this worktree", onPick: onFix)
            }
            if let bundle = model.resultBundlePath {
                Button("Open Results in Xcode", systemImage: "doc.richtext") {
                    onOpenResults(bundle)
                }
                .buttonStyle(LinkButtonStyle(.secondary))
                .hint("Opens the .xcresult bundle with every test, log and screenshot")
            }
        }
    }
}

#Preview {
    TestRunPanel(
        model: .preview,
        onCancel: {},
        onDismiss: {},
        onRunAgain: {},
        onOpenFailure: { _ in },
        onOpenIssue: { _ in },
        onOpenResults: { _ in },
        onFix: { _ in }
    )
    .padding()
    .frame(width: 640)
}
