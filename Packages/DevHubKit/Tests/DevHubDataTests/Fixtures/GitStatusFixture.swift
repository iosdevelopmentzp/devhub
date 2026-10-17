enum GitStatusFixture {
    static let porcelain = [
        "M  staged.swift",
        " M unstaged.swift",
        "MM both.swift",
        "A  added.swift",
        " D removed.swift",
        "R  renamed.swift",
        "old name.swift",
        "C  copy.swift",
        "source.swift",
        "RM moved.swift",
        "origin.swift",
        "T  type.swift",
        "X  weird.swift",
        "?? new folder/file.txt",
        "UU conflict.swift",
        "AA both-added.swift",
        "DD both-deleted.swift",
        "AU added-by-us.swift",
        "UD deleted-by-them.swift",
    ].joined(separator: "\0") + "\0"

    static let headerV2 = """
    # branch.oid 0123456789abcdef0123456789abcdef01234567
    # branch.head feature/ABC-1
    # branch.upstream origin/feature/ABC-1
    # branch.ab +2 -3
    1 .M N... 100644 100644 100644 abc abc Sources/File.swift
    2 R. N... 100644 100644 100644 abc abc R100 New.swift\tOld.swift
    ? untracked.txt

    """

    static let detachedHeaderV2 = """
    # branch.oid fedcba9876543210fedcba9876543210fedcba98
    # branch.head (detached)

    """
}
