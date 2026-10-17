import Foundation

package enum GitChangeKind: Hashable, Sendable {
    case modified
    case added
    case deleted
    case renamed
    case copied
    case untracked
    case conflicted
    case typeChanged
    case other(Character)

    package init(letter: Character) {
        switch letter {
        case "M": self = .modified
        case "A": self = .added
        case "D": self = .deleted
        case "R": self = .renamed
        case "C": self = .copied
        case "?": self = .untracked
        case "U": self = .conflicted
        case "T": self = .typeChanged
        default: self = .other(letter)
        }
    }

    package var letter: Character {
        switch self {
        case .modified: "M"
        case .added: "A"
        case .deleted: "D"
        case .renamed: "R"
        case .copied: "C"
        case .untracked: "?"
        case .conflicted: "U"
        case .typeChanged: "T"
        case .other(let letter): letter
        }
    }
}
