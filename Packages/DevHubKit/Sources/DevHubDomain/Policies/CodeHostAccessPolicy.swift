import Foundation

package enum CodeHostAccessPolicy {
    package static func requiredScopes(for kind: CodeHostKind) -> [CodeHostScope] {
        switch kind {
        case .github:
            [
                CodeHostScope(name: "repo", purpose: "pull requests", alternatives: []),
                CodeHostScope(name: "read:org", purpose: "teams as reviewers", alternatives: ["write:org", "admin:org"]),
                CodeHostScope(name: "notifications", purpose: "unsubscribe from pull requests", alternatives: []),
            ]
        case .gitlab:
            [
                CodeHostScope(name: "api", purpose: "merge request actions and unsubscribe", alternatives: []),
            ]
        }
    }

    package static func missingScopes(_ access: CodeHostAccess, kind: CodeHostKind) -> [CodeHostScope] {
        guard let scopes = access.scopes else { return [] }
        return requiredScopes(for: kind).filter { $0.isGranted(by: scopes) == false }
    }

    package static func fixCommand(missing: [CodeHostScope], host: CodeHost) -> String? {
        guard missing.isEmpty == false else { return nil }
        switch host.kind {
        case .github:
            return "gh auth refresh --hostname \(host.host) --scopes \(missing.map(\.name).joined(separator: ","))"
        case .gitlab:
            return loginCommand(host: host)
        }
    }

    package static func loginCommand(host: CodeHost) -> String {
        "\(host.tool) auth login --hostname \(host.host)"
    }
}
