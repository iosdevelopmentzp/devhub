import Foundation
import DevHubDomain

struct CodeHostWords: Equatable {
    static let gitHub = CodeHostWords(kind: .github)
    static let gitLab = CodeHostWords(kind: .gitlab)

    let kind: CodeHostKind?

    var name: String {
        switch kind {
        case .github: "GitHub"
        case .gitlab: "GitLab"
        case nil: "the code host"
        }
    }

    var hostTitle: String {
        kind == nil ? "The code host" : name
    }

    var openTitle: String {
        kind == nil ? "Open in Browser" : "Open in \(name)"
    }

    var openRequestTitle: String {
        kind == nil ? "Open \(requestTitle) in Browser" : "Open \(requestTitle) in \(name)"
    }

    var tool: String {
        switch kind {
        case .github: "gh"
        case .gitlab: "glab"
        case nil: "gh or glab"
        }
    }

    var request: String {
        kind == .gitlab ? "merge request" : "pull request"
    }

    var shortRequest: String {
        kind == .gitlab ? "MR" : "PR"
    }

    var requests: String {
        "\(request)s"
    }

    var requestTitle: String {
        kind == .gitlab ? "Merge Request" : "Pull Request"
    }

    var requestsTitle: String {
        "\(requestTitle)s"
    }

    var requestSentence: String {
        kind == .gitlab ? "Merge request" : "Pull request"
    }

    func reference(_ number: Int) -> String {
        kind == .gitlab ? "!\(number)" : "#\(number)"
    }

    var checks: String {
        kind == .gitlab ? "pipeline" : "checks"
    }

    var checksTitle: String {
        kind == .gitlab ? "Pipeline" : "Checks"
    }

    var checksPass: String {
        kind == .gitlab ? "the pipeline passes" : "the checks pass"
    }

    var job: String {
        kind == .gitlab ? "job" : "check"
    }

    var retryChecksTitle: String {
        kind == .gitlab ? "Retry Pipeline" : "Re-run Failed Checks"
    }

    var cancelChecksTitle: String {
        kind == .gitlab ? "Cancel Pipeline" : "Cancel Checks"
    }

    var mergeWhenChecksPassTitle: String {
        kind == .gitlab ? "Merge When Pipeline Passes…" : "Merge When Checks Pass…"
    }

    func updateBranchTitle(target: String) -> String {
        kind == .gitlab ? "Rebase onto \(target)" : "Update Branch from \(target)"
    }

    func updateBranchHint(target: String) -> String {
        switch kind {
        case .gitlab: "GitLab rebases the source branch onto \(target) on the server. Fails on conflicts."
        default: "\(hostTitle) merges \(target) into the source branch on the server. Fails on conflicts."
        }
    }

    var pageSize: Int {
        kind == .gitlab ? 100 : 50
    }

    func checks(_ gitLabVerb: String, _ gitHubVerb: String) -> String {
        kind == .gitlab ? "Pipeline \(gitLabVerb)" : "Checks \(gitHubVerb)"
    }

    func status(_ status: CheckStatus) -> String {
        guard kind != .gitlab else { return status.name }
        switch status {
        case .success: return "passed"
        case .failed: return "failed"
        case .canceled: return "cancelled"
        default: return status.name.replacingOccurrences(of: "_", with: " ")
        }
    }

    var updateWord: String {
        kind == .gitlab ? "rebase" : "update"
    }

    func catchUp(target: String) -> String {
        kind == .gitlab ? "rebase on \(target)" : "merge \(target) into the branch"
    }
}
