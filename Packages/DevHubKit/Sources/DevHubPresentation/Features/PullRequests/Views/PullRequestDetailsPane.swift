import SwiftUI
import DevHubUI

struct PullRequestDetailsPane: View {
    @Environment(AppActions.self) private var appActions
    @Environment(\.codeHostWords) private var words

    let model: PullRequestRowModel?
    let details: PullRequestDetailsModel?
    let isPickingLaunch: Bool
    let detailActions: PullRequestDetailActions
    let onRequestLaunch: () -> Void
    let onCancelLaunch: () -> Void
    let onAction: (PullRequestActionModel.Kind) -> Void
    let onMerge: (_ kind: PullRequestActionModel.Kind, _ squash: Bool, _ removeSourceBranch: Bool) -> Void

    @State private var isFinding = false
    @FocusState private var isFindFocused: Bool

    var body: some View {
        if let model, let details {
            VStack(spacing: 0) {
                header(model)
                Divider()
                if isFinding, case .loaded(let loaded) = details.content {
                    DiffFindBar(model: loaded.find, focus: $isFindFocused, onChange: detailActions.setFindQuery, onStep: { detailActions.stepFind($0, loaded.find.matches) }, onClose: closeFind)
                    Divider()
                }
                content(model: model, details: details)
            }
            .background {
                Button("Find", action: openFind)
                    .keyboardShortcut("f", modifiers: [.command, .option])
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .accessibilityHidden(true)
            }
        } else {
            ContentUnavailableView {
                Label("No \(words.request) selected", systemImage: "sidebar.right")
            } description: {
                Text("Click a \(words.request) on the left to read its description, threads and files here.")
            }
        }
    }

    private func header(_ model: PullRequestRowModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(model.reference)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .copyOnClick(model.reference, label: model.reference)
                Text(model.title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .hintWhenTruncated(model.title)
                Spacer(minLength: 4)
                ToggleIconButton(systemImage: "magnifyingglass", help: "Find text in the diffs of this \(words.request) (⌥⌘F)", isOn: isFinding) {
                    if isFinding {
                        closeFind()
                    } else {
                        openFind()
                    }
                }
                if let openWindow = detailActions.openWindow {
                    IconButton(systemImage: "macwindow", help: "Open this \(words.request) in its own window", action: openWindow)
                }
            }
            PullRequestFactsLine(model: model, isNarrow: true)
            if model.hasTags {
                PullRequestTagsFlow(model: model, onLabel: nil)
            }
            PullRequestActionBar(
                model: model,
                isPickingLaunch: isPickingLaunch,
                onRequestLaunch: onRequestLaunch,
                onCancelLaunch: onCancelLaunch,
                onAction: onAction,
                onMerge: onMerge,
                onFixThreads: detailActions.fixThreads,
                onConfigAction: detailActions.runConfigAction
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.base)
    }

    private func content(model: PullRequestRowModel, details: PullRequestDetailsModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    PullRequestDetailsView(
                        model: details,
                        actions: detailActions.withoutWindow
                    )
                }
                .padding(14)
                .coordinateSpace(.named(DiffViewport.coordinateSpace))
            }
            .modifier(DiffViewportModifier {
                if case .loaded(let loaded) = details.content {
                    PinnedFileHeader(files: loaded.files, actions: detailActions.withoutWindow)
                }
            })
            .environment(\.diffScrollProxy, proxy)
        }
        .id(model.id)
    }

    private func openFind() {
        isFinding = true
        Task { isFindFocused = true }
    }

    private func closeFind() {
        detailActions.endFind()
        isFinding = false
    }
}

#Preview {
    PullRequestDetailsPane(model: .preview, details: .preview, isPickingLaunch: false, detailActions: .preview, onRequestLaunch: {}, onCancelLaunch: {}, onAction: { _ in }, onMerge: { _, _, _ in })
        .previewEnvironment()
        .frame(width: 560, height: 600)
}
