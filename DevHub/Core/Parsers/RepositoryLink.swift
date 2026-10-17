import Foundation

nonisolated struct RepositoryLink: Hashable, Sendable {
    enum Host: Hashable, Sendable {
        case github
        case gitlab
    }

    let webURL: String
    let host: Host

    private static let safe = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
    private static let safePath = safe.union(CharacterSet(charactersIn: "/"))

    static func parse(remote: String) -> RepositoryLink? {
        let trimmed = remote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let (hostName, path) = split(trimmed) else { return nil }
        var cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if cleanPath.hasSuffix(".git") {
            cleanPath.removeLast(4)
        }
        guard hostName.isEmpty == false, cleanPath.isEmpty == false else { return nil }
        let host: Host = hostName.localizedCaseInsensitiveContains("gitlab") ? .gitlab : .github
        return RepositoryLink(webURL: "https://\(hostName)/\(cleanPath)", host: host)
    }

    func treeURL(branch: String?) -> String {
        guard let branch, branch.isEmpty == false else { return webURL }
        switch host {
        case .github: return webURL + "/tree/" + Self.encode(branch, allowed: Self.safePath)
        case .gitlab: return webURL + "/-/tree/" + Self.encode(branch, allowed: Self.safePath)
        }
    }

    func newRequestURL(branch: String, base: String) -> String {
        let target = base.hasPrefix("origin/") ? String(base.dropFirst("origin/".count)) : base
        switch host {
        case .github:
            return webURL + "/compare/" + Self.encode(target, allowed: Self.safePath) + "..." + Self.encode(branch, allowed: Self.safePath) + "?expand=1"
        case .gitlab:
            return webURL + "/-/merge_requests/new?merge_request[source_branch]=" + Self.encode(branch, allowed: Self.safe)
                + "&merge_request[target_branch]=" + Self.encode(target, allowed: Self.safe)
        }
    }

    private static func encode(_ value: String, allowed: CharacterSet) -> String {
        value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private static func split(_ remote: String) -> (String, String)? {
        if remote.contains("://") {
            guard let url = URL(string: remote), let host = url.host else { return nil }
            return (host, url.path)
        }
        guard let colon = remote.firstIndex(of: ":") else { return nil }
        let left = remote[..<colon]
        let host = left.split(separator: "@").last.map(String.init) ?? String(left)
        return (host, String(remote[remote.index(after: colon)...]))
    }
}
