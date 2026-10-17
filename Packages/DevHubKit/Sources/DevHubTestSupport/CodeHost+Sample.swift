import Foundation
import DevHubDomain

extension CodeHost {
    package static let gitLabSample = CodeHost(kind: .gitlab, host: "gitlab.example.com", path: "team/app", webURL: URL(string: "https://gitlab.example.com/team/app")!)
    package static let gitHubSample = CodeHost(kind: .github, host: "github.com", path: "example/app", webURL: URL(string: "https://github.com/example/app")!)
}
