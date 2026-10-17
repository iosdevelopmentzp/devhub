import DevHubDomain

enum GitFileChangeSample {
    static let staged = GitFileChange(path: "Sources/A.swift", originalPath: nil, area: .staged, kind: .modified)
    static let unstagedSamePath = GitFileChange(path: "Sources/A.swift", originalPath: nil, area: .unstaged, kind: .modified)
    static let unstaged = GitFileChange(path: "Sources/B.swift", originalPath: nil, area: .unstaged, kind: .modified)
    static let untracked = GitFileChange(path: "notes.txt", originalPath: nil, area: .untracked, kind: .untracked)
    static let conflicted = GitFileChange(path: "Sources/C.swift", originalPath: nil, area: .conflicted, kind: .conflicted)

    static let diff = GitDiff(lines: ["+added"], droppedLines: 0, isBinary: false)
}
