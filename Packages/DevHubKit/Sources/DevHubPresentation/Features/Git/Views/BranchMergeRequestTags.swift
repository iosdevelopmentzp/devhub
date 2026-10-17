import SwiftUI
import DevHubDomain
import DevHubUI

struct BranchMergeRequestTags: View {
    @Environment(AppActions.self) private var appActions

    let model: BranchMergeRequestModel

    var body: some View {
        HStack(spacing: 6) {
            Button {
                appActions.showMergeRequest(iid: model.iid)
            } label: {
                ModelTag(model: model.tag)
            }
            .buttonStyle(.plain)
            if let pipeline = model.pipelineTag {
                Button {
                    appActions.open(model.pipelineURL)
                } label: {
                    ModelTag(model: pipeline)
                }
                .buttonStyle(.plain)
            }
            ForEach(model.statusTags, id: \.self) { tag in
                ModelTag(model: tag)
            }
        }
    }
}

#Preview {
    BranchMergeRequestTags(model: .preview)
        .padding()
        .previewEnvironment()
}
