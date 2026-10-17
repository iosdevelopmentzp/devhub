import Foundation

nonisolated protocol PullRequestProviding: Sendable {
    func load(branch: String, repository: RepositoryLink, at path: String) async -> PullRequestLoad
}

nonisolated struct MockPullRequestProvider: PullRequestProviding {
    func load(branch: String, repository: RepositoryLink, at path: String) async -> PullRequestLoad {
        .found(PullRequestInfo(number: 1360, state: .draft, url: repository.webURL, hasConflicts: false, review: "review required", checks: .passing, isMergeRequest: repository.host == .gitlab))
    }
}

nonisolated struct LivePullRequestProvider: PullRequestProviding {
    let shell: ShellRunner
    let tools: ToolLocating

    func load(branch: String, repository: RepositoryLink, at path: String) async -> PullRequestLoad {
        switch repository.host {
        case .github: await loadGitHub(branch: branch, path: path)
        case .gitlab: await loadGitLab(branch: branch, repository: repository, path: path)
        }
    }

    private func loadGitHub(branch: String, path: String) async -> PullRequestLoad {
        guard tools.isInstalled("gh") else { return .notInstalled(command: "brew install gh") }
        let fields = "number,state,isDraft,url,mergeable,reviewDecision,statusCheckRollup,baseRefName"
        guard let result = try? await shell.run("gh", ["pr", "view", branch, "--json", fields], cwd: path) else {
            return .failed("Could not start gh.")
        }
        if result.exitCode == 0 {
            return PullRequestParser.parseGitHub(result.stdout).map(PullRequestLoad.found) ?? .failed("Unexpected output from gh.")
        }
        return failure(result, login: "gh auth login")
    }

    private func loadGitLab(branch: String, repository: RepositoryLink, path: String) async -> PullRequestLoad {
        guard tools.isInstalled("glab") else { return .notInstalled(command: "brew install glab") }
        guard let target = Self.hostAndProject(repository.webURL) else { return .failed("Unknown repository address.") }
        let login = "glab auth login --hostname \(target.host)"
        let encodedProject = target.project.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-._~"))) ?? target.project
        let encodedBranch = branch.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-._~"))) ?? branch
        let base = "projects/\(encodedProject)"
        guard let requests = try? await shell.run("glab", ["api", "--hostname", target.host, "\(base)/merge_requests?source_branch=\(encodedBranch)&state=all&order_by=updated_at&per_page=5"], cwd: path) else {
            return .failed("Could not start glab.")
        }
        guard requests.exitCode == 0 else { return failure(requests, login: login) }
        let pipelines = try? await shell.run("glab", ["api", "--hostname", target.host, "\(base)/pipelines?ref=\(encodedBranch)&per_page=1"], cwd: path)
        guard let info = PullRequestParser.parseGitLab(requests: requests.stdout, pipelines: pipelines?.stdout) else { return PullRequestLoad.none }
        return .found(info)
    }

    private func failure(_ result: ShellResult, login: String) -> PullRequestLoad {
        let message = result.failureMessage
        let lowered = message.lowercased()
        if lowered.contains("no pull requests found") || lowered.contains("no open pull requests") {
            return PullRequestLoad.none
        }
        if lowered.contains("auth login") || lowered.contains("not logged in") || lowered.contains("401") || lowered.contains("authentication") {
            return .notLoggedIn(command: login)
        }
        return .failed(message)
    }

    private static func hostAndProject(_ webURL: String) -> (host: String, project: String)? {
        guard let url = URL(string: webURL), let host = url.host else { return nil }
        let project = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return project.isEmpty ? nil : (host, project)
    }
}
