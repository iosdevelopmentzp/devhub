import Foundation
import DevHubUI

struct PullRequestDetailsModel: Equatable {
    enum Content: Equatable {
        case loading
        case failure(String)
        case loaded(Loaded)
    }

    struct JobLink: Equatable, Hashable {
        var title: String
        var url: URL?
    }

    struct Loaded: Equatable {
        var pipelineTag: TagModel?
        var pipelineURL: URL?
        var pipelineDurationText: String?
        var canCancelPipeline: Bool
        var failedJobs: [JobLink]
        var jobsTitle: String
        var jobGroups: [PipelineJobGroupModel]
        var reviewLines: [PullRequestReviewLineModel]
        var description: AttributedString?
        var threadsTitle: String
        var canFixThreads: Bool
        var threads: [ReviewThreadRowModel]
        var commentBox: PullRequestCommentBoxModel
        var filesTitle: String
        var hiddenFilesTitle: String?
        var hiddenFilesHint: String?
        var showsHiddenFiles: Bool
        var canExpandAllFiles: Bool
        var canCollapseAllFiles: Bool
        var hasThreadsInDiff: Bool
        var showsThreadsInDiff: Bool
        var files: [PullRequestFileRowModel]
    }

    var content: Content

    static let preview = PullRequestDetailsModel(
        content: .loaded(
            Loaded(
                pipelineTag: TagModel("pipeline running", tint: .blue, systemImage: "play.circle.fill", hint: "Pipeline of the last commit. Click to open it."),
                pipelineURL: URL(string: "https://gitlab.com/example/app/-/pipelines/1842"),
                pipelineDurationText: "9 m 0 s",
                canCancelPipeline: true,
                failedJobs: [],
                jobsTitle: "Pipeline 1 · 1 failed",
                jobGroups: [.preview],
                reviewLines: [
                    .preview,
                    PullRequestReviewLineModel(id: "waiting", title: "Waiting for", tags: [TagModel("sam", tint: .orange, systemImage: "hourglass", hint: "Review requested from sam, no answer yet")]),
                ],
                description: AttributedString("Adds paid calls.\n\nTicket: ABC-2324"),
                threadsTitle: "Open threads 1",
                canFixThreads: true,
                threads: [.preview],
                commentBox: .preview,
                filesTitle: "Files 1 · +2 −1",
                hiddenFilesTitle: "Show 2 hidden",
                hiddenFilesHint: "2 files match git.pullRequests.hiddenFiles. Click to show them.",
                showsHiddenFiles: false,
                canExpandAllFiles: false,
                canCollapseAllFiles: true,
                hasThreadsInDiff: true,
                showsThreadsInDiff: true,
                files: [.preview]
            )
        )
    )
}
