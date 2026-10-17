import DevHubDomain
import Foundation

enum MergeRequestFixture {
    static let url = URL(string: "https://gitlab.example.com/top/live/-/merge_requests/12")

    static func request(state: MergeRequestState, isDraft: Bool, hasConflicts: Bool, detail: MergeDetail?) -> MergeRequestInfo {
        MergeRequestInfo(
            iid: 12,
            title: "ABC-1: Login screen",
            state: state,
            isDraft: isDraft,
            webURL: url,
            author: "alex",
            hasConflicts: hasConflicts,
            detailedStatus: detail,
            targetBranch: "dev"
        )
    }

    static func pipeline(_ status: PipelineStatus) -> PipelineInfo {
        PipelineInfo(status: status, webURL: URL(string: "https://gitlab.example.com/top/live/-/pipelines/7"), updatedAt: nil)
    }
}
