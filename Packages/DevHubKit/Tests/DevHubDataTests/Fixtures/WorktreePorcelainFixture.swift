enum WorktreePorcelainFixture {
    static let listing = """
    worktree /Users/me/App
    HEAD 0123456789abcdef
    branch refs/heads/main

    worktree /Users/me/App/.claude/worktrees/feature-x
    HEAD abcdef0123456789
    branch refs/heads/feature/x
    locked agent is working

    worktree /Users/me/App-detached
    HEAD 9999999999999999
    detached
    prunable gitdir file points to non-existent location

    worktree /Users/me/App-locked
    HEAD 1111111111111111
    branch refs/heads/locked
    locked
    prunable

    """
}
