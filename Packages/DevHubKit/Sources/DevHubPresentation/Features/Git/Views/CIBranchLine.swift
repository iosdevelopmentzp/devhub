import SwiftUI
import DevHubDomain
import DevHubUI

struct CIBranchLine: View {
    @Environment(AppActions.self) private var appActions

    let model: CIBranchLineModel
    let onRefresh: () -> Void
    let onRerun: (_ workflowID: String, _ name: String) -> Void
    let onCancel: (_ workflowID: String, _ name: String) -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.hexagongrid")
                .foregroundStyle(.secondary)
                .hint(model.iconHint)
            content
            Spacer(minLength: 0)
            if let url = model.openURL {
                IconButton(systemImage: "globe", help: model.openHint) {
                    appActions.open(url)
                }
            }
            if model.isLoading {
                ProgressView()
                    .controlSize(.mini)
            } else {
                IconButton(systemImage: "arrow.clockwise", help: model.refreshHint) {
                    onRefresh()
                }
            }
        }
        .font(.caption)
    }

    @ViewBuilder
    private var content: some View {
        switch model.content {
        case .checking:
            Text("Checking CircleCI…")
                .foregroundStyle(.secondary)
        case .failure(let message):
            Text(message)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .hintWhenTruncated(message)
        case .noRun(let text):
            Text(text)
                .foregroundStyle(.secondary)
        case .run(let run):
            runContent(run)
        }
    }

    private func runContent(_ run: CIBranchLineModel.Run) -> some View {
        FlowLayout(spacing: 6, lineSpacing: 4) {
            ForEach(run.workflows) { workflow in
                HStack(spacing: 2) {
                    ModelTag(model: workflow.tag)
                    if workflow.isBusy {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        if workflow.canRerun {
                            IconButton(systemImage: "arrow.counterclockwise", help: workflow.rerunHint) {
                                onRerun(workflow.id, workflow.name)
                            }
                        }
                        if workflow.canCancel {
                            IconButton(systemImage: "stop.circle", help: workflow.cancelHint) {
                                onCancel(workflow.id, workflow.name)
                            }
                        }
                    }
                }
            }
            if let subject = run.subject {
                Text(subject)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .hintWhenTruncated(subject)
            }
            if let age = run.ageText {
                Text(age)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    CIBranchLine(model: .preview, onRefresh: {}, onRerun: { _, _ in }, onCancel: { _, _ in })
        .padding()
        .previewEnvironment()
}
