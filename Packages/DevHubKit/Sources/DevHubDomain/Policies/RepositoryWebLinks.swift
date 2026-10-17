import Foundation

package enum RepositoryWebLinks {

    package static func branchURL(base: URL, branch: String) -> URL? {
        let local = BranchName(branch).local
        let path = isGitHub(base) ? "/tree/\(local)" : "/-/tree/\(local)"
        return URL(string: base.absoluteString + path)
    }

    package static func newMergeRequestURL(base: URL, branch: String, baseName: String) -> URL? {
        let local = BranchName(branch).local
        let encoded = local.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? local
        let suffix = isGitHub(base)
            ? "/compare/\(baseName)...\(encoded)?expand=1"
            : "/-/merge_requests/new?merge_request%5Bsource_branch%5D=\(encoded)&merge_request%5Btarget_branch%5D=\(baseName)"
        return URL(string: base.absoluteString + suffix)
    }

    package static func commitURL(base: URL, hash: String) -> URL? {
        let path = isGitHub(base) ? "/commit/\(hash)" : "/-/commit/\(hash)"
        return URL(string: base.absoluteString + path)
    }

    private static func isGitHub(_ base: URL) -> Bool {
        base.host()?.contains("github") == true
    }
}
