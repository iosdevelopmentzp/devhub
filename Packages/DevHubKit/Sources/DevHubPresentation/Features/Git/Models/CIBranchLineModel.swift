import Foundation
import DevHubDomain
import DevHubUI

struct CIBranchLineModel: Equatable {
    enum Content: Equatable {
        case checking
        case failure(String)
        case noRun(String)
        case run(Run)
    }

    struct Run: Equatable {
        var subject: String?
        var ageText: String?
        var workflows: [Workflow]
    }

    struct Workflow: Equatable, Identifiable {
        let id: String
        var name: String
        var tag: TagModel
        var isBusy: Bool
        var canRerun: Bool
        var canCancel: Bool
        var rerunHint: String
        var cancelHint: String
    }

    var content: Content
    var isLoading: Bool
    var openURL: URL?
    var iconHint: String
    var openHint = "Open the pipelines of this branch in CircleCI"
    var refreshHint = "Ask CircleCI again"

    static let preview = CIBranchLineModel(
        content: .run(
            Run(
                subject: "ABC-123: Retry the login after a timeout",
                ageText: "40 min. ago",
                workflows: [
                    Workflow(id: "w1", name: "build-and-test", tag: TagModel("build-and-test failed", tint: .red, systemImage: "xmark.circle.fill", hint: "CircleCI workflow build-and-test failed"), isBusy: false, canRerun: true, canCancel: false, rerunHint: "Run the failed jobs of build-and-test again", cancelHint: "Cancel build-and-test"),
                    Workflow(id: "w2", name: "nightly", tag: TagModel("nightly passed", tint: .green, systemImage: "checkmark.circle.fill", hint: "CircleCI workflow nightly passed"), isBusy: false, canRerun: false, canCancel: false, rerunHint: "", cancelHint: ""),
                ]
            )
        ),
        isLoading: false,
        openURL: nil,
        iconHint: "CircleCI runs of this branch, read with circleci"
    )
}
