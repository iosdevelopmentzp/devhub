import SwiftUI
import DevHubUI

struct PullRequestDetailsPane: View {
    @Environment(PullRequestDetailStore.self) private var detailStore
    @Environment(AppActions.self) private var appActions

    let model: PullRequestRowModel?
    let details: PullRequestDetailsModel?
    let isPickingLaunch: Bool
    let detailActions: PullRequestDetailActions
    let onRequestLaunch: () -> Void
    let onCancelLaunch: () -> Void
    let onAction: (PullRequestActionModel.Kind) -> Void
    let onMerge: (_ kind: PullRequestActionModel.Kind, _ squash: Bool, _ removeSourceBranch: Bool) -> Void

    var body: some View {
        if let model, let details {
            VStack(spacing: 0) {
                header(model)
                Divider()
                content(model: model, details: details)
            }
        } else {
            ContentUnavailableView {
                Label("No merge request selected", systemImage: "sidebar.right")
            } description: {
                Text("Click a merge request on the left to read its description, threads and files here.")
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
                if let openWindow = detailActions.openWindow {
                    IconButton(systemImage: "macwindow", help: "Open this merge request in its own window", action: openWindow)
                }
            }
            PullRequestActionBar(
                model: model,
                isPickingLaunch: isPickingLaunch,
                onRequestLaunch: onRequestLaunch,
                onCancelLaunch: onCancelLaunch,
                onAction: onAction,
                onMerge: onMerge,
                onFixThreads: detailActions.fixThreads
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.base)
    }

    private func content(model: PullRequestRowModel, details: PullRequestDetailsModel) -> some View {
        let id = model.id
        return ScrollViewReader { proxy in
            ScrollView {
                PullRequestDetailsView(
                    model: details,
                    actions: detailActions.withoutWindow
                )
                .padding(14)
            }
            .environment(\.diffScrollProxy, proxy)
            .onChange(of: detailStore.focus(of: id)) { _, focus in
                guard let focus else { return }
                withAnimation(.snappy(duration: 0.25)) {
                    proxy.scrollTo(PullRequestFileRowModel.scrollID(focus.path), anchor: .top)
                }
            }
        }
        .id(id)
    }
}

#Preview {
    PullRequestDetailsPane(model: .preview, details: .preview, isPickingLaunch: false, detailActions: .preview, onRequestLaunch: {}, onCancelLaunch: {}, onAction: { _ in }, onMerge: { _, _, _ in })
        .previewEnvironment()
        .frame(width: 560, height: 600)
}
