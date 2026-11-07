# ADR 013. Stash contents and the branches of a commit

Date: 2026-11-07. Status: done, 2026-11-07 (see the step log).

## Context

The Stash section listed the entries with their message, reference, branch and date, and nothing more: the only way to see what a stash holds was to apply it. The History section already marks the refs that point at a commit (HEAD, branches, remote branches, tags, from `git log --decorate=full`), but a branch that merely contains the commit stays invisible. The owner asked to see the changes of a stash, and the branches of a commit.

## Decisions

### D1. A stash is a commit with files and diffs

`GitStash` carries the commit hash of the stash (`git stash list --format=%gd%x09%H%x09%ct%x09%gs`). A click on a stash row expands it like a commit: `GitChangesRepository.stashFiles` lists the tracked changes (`git show --first-parent --name-status -z --format= <hash>`) and the untracked files of the stash (`git show --name-status -z --format= <hash>^3`, ignored when the stash has no third parent) as `.untracked`; `stashDiff` reads a tracked file with the commit diff and an untracked one from `<hash>^3`. `CommitHistoryStore` keeps the expansion (`expandedRow` is `stash:<hash>`, `stashHashes` says which hashes need the stash commands) and the row reuses `CommitFilesList`, `CommitFileRow` and `DiffView`. The hash, not `stash@{n}`, is the key, because the index moves when a stash is dropped.

### D2. Create a branch from a stash

The row menu gets "Create Branch from Stash…": an inline name field under the row, then `git stash branch <name> stash@{n}` (`GitCommand.stashBranch`): a branch from the commit the stash was made on, with the stash applied and dropped. This is the way out when a stash no longer applies on the current branch.

### D3. The branches that contain a commit

Expanding a commit in History or Reflog also runs `git branch -a --contains <hash> --format=%(refname)` (`GitChangesRepository.branchesContaining`, `GitContainingBranchesParser`). The row shows them as an "In …" line of branch tags above the files, local and remote, or "In no branch". The result is cached per hash until the branches change. The decorations on the row itself stay as they were.

## Consequences

- Two more `git show` calls per expanded stash and one `git branch --contains` per expanded commit; nothing runs for a folded row.
- The debug switches `DEVHUB_GIT_SECTION=<Local|Remote|History|Reflog|Changes|Stash>` and `DEVHUB_GIT_EXPAND=stash:<index>|commit:<hash>` let a headless snapshot show a section and an expanded row.

## Step log

| Commit | What |
|---|---|
