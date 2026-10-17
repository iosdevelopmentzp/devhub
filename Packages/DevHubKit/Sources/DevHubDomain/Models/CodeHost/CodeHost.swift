import Foundation

package struct CodeHost: Hashable, Sendable {
    package let kind: CodeHostKind
    package let host: String
    package let path: String
    package let webURL: URL

    package init(kind: CodeHostKind, host: String, path: String, webURL: URL) {
        self.kind = kind
        self.host = host
        self.path = path
        self.webURL = webURL
    }

    package var name: String {
        switch kind {
        case .github: "GitHub"
        case .gitlab: "GitLab"
        }
    }

    package var requestNoun: String {
        switch kind {
        case .github: "pull request"
        case .gitlab: "merge request"
        }
    }

    package var referencePrefix: String {
        switch kind {
        case .github: "#"
        case .gitlab: "!"
        }
    }

    package var tool: String {
        switch kind {
        case .github: "gh"
        case .gitlab: "glab"
        }
    }
}
