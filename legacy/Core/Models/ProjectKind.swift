import Foundation

nonisolated enum ProjectKind: String, Codable, Hashable, Sendable {
    case xcode
    case command
}

nonisolated enum ContainerKind: String, Hashable, Sendable {
    case workspace
    case project
}

nonisolated struct ProjectDetection: Hashable, Sendable {
    var container: String?
    var containerKind: ContainerKind?
    var schemes: [String]
    var bundleID: String?
    var kind: ProjectKind
    var isGitRepository: Bool
    var baseBranch: String?

    var kindTitle: String {
        switch containerKind {
        case .workspace: "Xcode workspace"
        case .project: "Xcode project"
        case nil: "Command-based"
        }
    }

    static let empty = ProjectDetection(
        container: nil,
        containerKind: nil,
        schemes: [],
        bundleID: nil,
        kind: .command,
        isGitRepository: false,
        baseBranch: nil
    )
}
