import Foundation
import DevHubDomain

enum CIDiagnosticsSubjectsMapper {

    static func subjects(host: CodeHost?, currentBranch: String?, baseName: String, requests: [PullRequestSummary], username: String?, home: String) -> CIRedactionSubjects {
        let parts = host?.path.split(separator: "/").map(String.init) ?? []
        var branches = Set(requests.flatMap { [$0.sourceBranch, $0.targetBranch] })
        branches.insert(baseName)
        if let currentBranch {
            branches.insert(currentBranch)
        }
        var logins = Set(requests.flatMap { [$0.author] + $0.approvedBy + $0.assignees + $0.reviewers + $0.changesRequestedBy })
        if let username {
            logins.insert(username)
        }
        return CIRedactionSubjects(
            organization: parts.first,
            repository: parts.count > 1 ? parts.last : nil,
            host: host?.host,
            branches: branches.filter { $0.isEmpty == false }.sorted(),
            logins: logins.filter { $0.isEmpty == false }.sorted(),
            homeFolder: home
        )
    }
}
