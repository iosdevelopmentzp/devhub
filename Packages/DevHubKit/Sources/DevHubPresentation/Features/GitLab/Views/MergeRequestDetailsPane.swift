import SwiftUI
import DevHubUI

struct MergeRequestDetailsPane: View {
    @Environment(MergeRequestDetailStore.self) private var detailStore
    @Environment(AppActions.self) private var appActions

    let model: MergeRequestRowModel?
    let details: MergeRequestDetailsModel?
    let isPickingLaunch: Bool
    let detailActions: MergeRequestDetailActions
    let onRequestLaunch: () -> Void
    let onCancelLaunch: () -> Void
    let onAction: (MergeRequestActionModel.Kind) -> Void
    let onMerge: (_ kind: MergeRequestActionModel.Kind, _ squash: Bool, _ removeSourceBranch: Bool) -> Void

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

    private func header(_ model: MergeRequestRowModel) -> some View {
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
            MergeRequestActionBar(
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

    private func content(model: MergeRequestRowModel, details: MergeRequestDetailsModel) -> some View {
        let id = model.id
        return ScrollViewReader { proxy in
            ScrollView {
                MergeRequestDetailsView(
                    model: details,
                    actions: detailActions.withoutWindow
                )
                .padding(14)
            }
            .environment(\.diffScrollProxy, proxy)
            .onChange(of: detailStore.focus(of: id)) { _, focus in
                guard let focus else { return }
                withAnimation(.snappy(duration: 0.25)) {
                    proxy.scrollTo(MergeRequestFileRowModel.scrollID(focus.path), anchor: .top)
                }
            }
        }
        .id(id)
    }
}

#Preview {
    MergeRequestDetailsPane(model: .preview, details: .preview, isPickingLaunch: false, detailActions: .preview, onRequestLaunch: {}, onCancelLaunch: {}, onAction: { _ in }, onMerge: { _, _, _ in })
        .previewEnvironment()
        .frame(width: 560, height: 600)
}
