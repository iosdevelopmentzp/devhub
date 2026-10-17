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

    package var id: String {
        "builtin.\(rawValue)"
    }

    package static func named(_ id: String) -> BuiltinAction? {
        allCases.first { $0.id == id }
    }
}
