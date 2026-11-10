import SwiftUI
import DevHubUI

struct PinnedFileHeader: View {
    @Environment(DiffViewport.self) private var viewport: DiffViewport?

    let files: [PullRequestFileRowModel]
    let actions: PullRequestDetailActions

    var body: some View {
        if let pinned = viewport?.pinnedHeader, let model = files.first(where: { $0.id == pinned.id }) {
            PullRequestFileHeader(model: model, actions: actions, isWide: PullRequestDetailsView.isWide(contentWidth: pinned.frame.width))
                .overlay(alignment: .bottom) {
                    Divider()
                }
                .frame(width: pinned.frame.width)
                .offset(x: pinned.frame.minX, y: pinned.offset)
        }
    }
}

#Preview {
    PinnedFileHeader(files: [.preview], actions: .preview)
        .previewEnvironment()
        .frame(width: 640)
}
