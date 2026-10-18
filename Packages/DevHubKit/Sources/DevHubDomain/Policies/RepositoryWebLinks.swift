import Foundation

package enum RepositoryWebLinks {

    package static func branchURL(base: URL, kind: CodeHostKind?, branch: String, remote: String) -> URL? {
        let local = BranchName(branch, remote: remote).local
        let path = isGitHub(base, kind) ? "/tree/\(local)" : "/-/tree/\(local)"
        return URL(string: base.absoluteString + path)
    }

    package static func newPullRequestURL(base: URL, kind: CodeHostKind?, branch: String, baseName: String, remote: String) -> URL? {
        let local = BranchName(branch, remote: remote).local
        let encoded = local.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? local
        let suffix = isGitHub(base, kind)
            ? "/compare/\(baseName)...\(encoded)?expand=1"
            : "/-/merge_requests/new?merge_request%5Bsource_branch%5D=\(encoded)&merge_request%5Btarget_branch%5D=\(baseName)"
        return URL(string: base.absoluteString + suffix)
    }

    package static func commitURL(base: URL, kind: CodeHostKind?, hash: String) -> URL? {
        let path = isGitHub(base, kind) ? "/commit/\(hash)" : "/-/commit/\(hash)"
        return URL(string: base.absoluteString + path)
    }

    private static func isGitHub(_ base: URL, _ kind: CodeHostKind?) -> Bool {
        (kind ?? CodeHostPolicy.kind(forHost: base.host() ?? "")) == .github
    }
}
