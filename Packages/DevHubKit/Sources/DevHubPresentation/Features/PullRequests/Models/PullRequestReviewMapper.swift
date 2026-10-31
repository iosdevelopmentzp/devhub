import Foundation
import DevHubDomain
import DevHubUI

enum PullRequestReviewMapper {

    static func lines(for request: PullRequestSummary, username: String?, words: CodeHostWords) -> [PullRequestReviewLineModel] {
        let answered = Set(request.approvedBy + request.changesRequestedBy)
        let waiting = request.reviewers.filter { answered.contains($0) == false }
        var lines: [PullRequestReviewLineModel] = []
        if request.approvedBy.isEmpty == false {
            lines.append(PullRequestReviewLineModel(
                id: "approved",
                title: "Approved by",
                tags: request.approvedBy.map { TagModel(name($0, username: username), tint: .green, systemImage: "checkmark.seal.fill", hint: "\(name($0, username: username, capitalized: true)) approved this \(words.request)") }
            ))
        }
        if request.changesRequestedBy.isEmpty == false {
            lines.append(PullRequestReviewLineModel(
                id: "changes",
                title: "Changes requested",
                tags: request.changesRequestedBy.map { TagModel(name($0, username: username), tint: .red, systemImage: "xmark.circle.fill", hint: "\(name($0, username: username, capitalized: true)) asked for changes before this \(words.request) can merge") }
            ))
        }
        if request.state == .opened {
            if waiting.isEmpty == false {
                lines.append(PullRequestReviewLineModel(
                    id: "waiting",
                    title: "Waiting for",
                    tags: waiting.map { TagModel(name($0, username: username), tint: .orange, systemImage: "hourglass", hint: "Review requested from \(name($0, username: username)), no answer yet") }
                ))
            } else if request.reviewers.isEmpty, request.approvedBy.isEmpty {
                lines.append(PullRequestReviewLineModel(
                    id: "waiting",
                    title: "Reviewers",
                    tags: [TagModel("none requested", tint: .secondary, systemImage: "person.badge.plus", hint: "Nobody was asked to review this \(words.request) yet")]
                ))
            }
        }
        if request.assignees.isEmpty == false {
            lines.append(PullRequestReviewLineModel(
                id: "assignees",
                title: "Assigned to",
                tags: request.assignees.map { TagModel(name($0, username: username), tint: .secondary, systemImage: "person.fill", hint: "\(name($0, username: username, capitalized: true)) is assigned to this \(words.request)") }
            ))
        }
        return lines
    }

    private static func name(_ login: String, username: String?, capitalized: Bool = false) -> String {
        guard login == username else { return login }
        return capitalized ? "You" : "you"
    }
}
