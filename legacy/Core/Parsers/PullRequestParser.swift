import Foundation

nonisolated enum PullRequestParser {
    static func parseGitHub(_ json: String) -> PullRequestInfo? {
        guard let object = object(json) else { return nil }
        guard let number = object["number"] as? Int else { return nil }
        let rawState = (object["state"] as? String ?? "").uppercased()
        let isDraft = object["isDraft"] as? Bool ?? false
        let state: PullRequestInfo.State
        switch rawState {
        case "MERGED": state = .merged
        case "CLOSED": state = .closed
        default: state = isDraft ? .draft : .open
        }
        return PullRequestInfo(
            number: number,
            state: state,
            url: object["url"] as? String ?? "",
            hasConflicts: (object["mergeable"] as? String) == "CONFLICTING",
            review: reviewText(object["reviewDecision"] as? String),
            checks: githubChecks(object["statusCheckRollup"] as? [[String: Any]] ?? []),
            isMergeRequest: false
        )
    }

    static func parseGitLab(requests json: String, pipelines pipelineJSON: String?) -> PullRequestInfo? {
        guard let list = array(json) else { return nil }
        let chosen = list.first { ($0["state"] as? String) == "opened" } ?? list.first
        guard let request = chosen, let number = request["iid"] as? Int else { return nil }
        let rawState = request["state"] as? String ?? ""
        let isDraft = (request["draft"] as? Bool ?? false) || (request["work_in_progress"] as? Bool ?? false)
        let state: PullRequestInfo.State
        switch rawState {
        case "merged": state = .merged
        case "closed": state = .closed
        default: state = isDraft ? .draft : .open
        }
        return PullRequestInfo(
            number: number,
            state: state,
            url: request["web_url"] as? String ?? "",
            hasConflicts: request["has_conflicts"] as? Bool ?? false,
            review: mergeStatusText(request["detailed_merge_status"] as? String),
            checks: pipelineJSON.map(gitlabChecks) ?? .none,
            isMergeRequest: true
        )
    }

    private static func object(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    private static func array(_ json: String) -> [[String: Any]]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    }

    private static func reviewText(_ decision: String?) -> String? {
        switch decision {
        case "APPROVED": "approved"
        case "CHANGES_REQUESTED": "changes requested"
        case "REVIEW_REQUIRED": "review required"
        default: nil
        }
    }

    private static func mergeStatusText(_ status: String?) -> String? {
        guard let status, status.isEmpty == false else { return nil }
        return status.replacingOccurrences(of: "_", with: " ")
    }

    private static func githubChecks(_ rollup: [[String: Any]]) -> PullRequestInfo.Checks {
        guard rollup.isEmpty == false else { return .none }
        let failing: Set<String> = ["FAILURE", "TIMED_OUT", "STARTUP_FAILURE", "ERROR", "ACTION_REQUIRED"]
        var pending = false
        for check in rollup {
            let result = (check["conclusion"] as? String ?? check["state"] as? String ?? "").uppercased()
            let status = (check["status"] as? String ?? "").uppercased()
            if failing.contains(result) {
                return .failing
            }
            if result.isEmpty || result == "PENDING" || (status.isEmpty == false && status != "COMPLETED") {
                pending = true
            }
        }
        return pending ? .pending : .passing
    }

    private static func gitlabChecks(_ json: String) -> PullRequestInfo.Checks {
        guard let first = array(json)?.first else { return .none }
        switch first["status"] as? String ?? "" {
        case "success": return .passing
        case "failed": return .failing
        case "running", "pending", "created", "preparing", "waiting_for_resource", "scheduled": return .pending
        default: return .none
        }
    }
}
