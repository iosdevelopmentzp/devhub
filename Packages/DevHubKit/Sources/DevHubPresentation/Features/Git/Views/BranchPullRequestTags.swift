import SwiftUI
import DevHubDomain
import DevHubUI

struct BranchPullRequestTags: View {
    @Environment(AppActions.self) private var appActions

    let model: BranchPullRequestModel

    var body: some View {
        HStack(spacing: 6) {
            Button {
                appActions.showPullRequest(iid: model.iid)
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
    BranchPullRequestTags(model: .preview)
        .padding()
        .previewEnvironment()
}
