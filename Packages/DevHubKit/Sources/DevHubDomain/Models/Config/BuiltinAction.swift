import Foundation

package enum BuiltinAction: String, CaseIterable, Hashable, Sendable {
    case buildRun
    case runAttach
    case openEditor
    case openFolder
    case terminal
    case copyBranch
    case repository
    case newPullRequest
    case pullRequests

    package static let homeDefaults = allCases.filter { $0 != .pullRequests }

    package var id: String {
        "builtin.\(rawValue)"
    }

    package static func named(_ id: String) -> BuiltinAction? {
        allCases.first { $0.id == id }
    }
}
