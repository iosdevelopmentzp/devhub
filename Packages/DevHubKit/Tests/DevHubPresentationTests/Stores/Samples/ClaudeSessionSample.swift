import Foundation
import DevHubDomain

enum ClaudeSessionSample {
    static let root = session(id: "root", cwd: ProjectSample.path)
    static let nested = session(id: "nested", cwd: ProjectSample.path + "/Sources")
    static let sibling = session(id: "sibling", cwd: ProjectSample.path + "-feature")
    static let elsewhere = session(id: "elsewhere", cwd: "/tmp/DevHubTests/Other")

    static let all = [root, nested, sibling, elsewhere]

    static func session(id: String, cwd: String) -> ClaudeSession {
        ClaudeSession(
            id: id,
            title: "Session \(id)",
            lastPrompt: nil,
            cwd: cwd,
            gitBranch: nil,
            startedAt: nil,
            updatedAt: Date(timeIntervalSince1970: 0),
            folderExists: true
        )
    }
}
