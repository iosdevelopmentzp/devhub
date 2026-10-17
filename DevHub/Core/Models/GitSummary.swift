import Foundation

nonisolated struct GitSummary: Hashable, Sendable {
    var branch: String?
    var changeCount: Int
    var ahead: Int
    var behind: Int

    var isClean: Bool { changeCount == 0 }

    var changesText: String {
        changeCount == 1 ? "1 change" : "\(changeCount) changes"
    }

    static let notARepository = GitSummary(branch: nil, changeCount: 0, ahead: 0, behind: 0)
}
