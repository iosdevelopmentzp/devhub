import Foundation

package enum CodeHostPolicy {
    package static func codeHost(webURL: URL, kind configuredKind: CodeHostKind?, name configuredName: String?) -> CodeHost? {
        guard let host = webURL.host(), host.isEmpty == false else { return nil }
        let path = webURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard path.isEmpty == false else { return nil }
        return CodeHost(
            kind: configuredKind ?? kind(forHost: host),
            host: configuredName ?? host,
            path: path,
            webURL: webURL
        )
    }

    package static func kind(forHost host: String) -> CodeHostKind {
        host.lowercased().contains("github") ? .github : .gitlab
    }
}
