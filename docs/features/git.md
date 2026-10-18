# Git

The Git tab (⌘2) shows one checkout of the project: its branch, the local and remote branches, the history, the reflog, the uncommitted changes and the stash. Every action runs `git` through `ShellRunner`, so each command appears in the Output panel.

Code: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Git/`, `DevHubDomain/Models/GitCommand.swift`, `DevHubDomain/UseCases/`, `DevHubData/Git/`.

In the commands below, `<remote>` is `git.remote` (default `origin`), `<base>` is the base branch ref (for example `origin/main`) and `<baseName>` is its local name (for example `main`).

## What it shows

### Header

1. **Checkout menu.** "Main checkout" or "Worktree <name>". The actions of the tab run in the checkout you choose here.
2. **Last fetch time** ("fetched 5 min ago"), or the title of the running command. A refresh button reads the repository again.
3. **Branch line.** The branch name (click to copy), the short hash (click to copy) and tags:
   - ticket chip (when the branch name matches the ticket pattern);
   - `clean` or `N changed`;
   - the upstream branch;
   - `↑N to push`, `↓N to pull`, or `not pushed` when the branch has no upstream;
   - `N behind <base>` and `N ahead of <base>`;
   - `N stashed` (click to show the Stash section).
4. **Request line.** Shown when the remote has a web URL and HEAD is on a branch. It shows the pull request (GitHub) or merge request (GitLab) of the branch: `#12 open` or `!12 open`, draft, merged or closed, conflicts, merge status, approvals, open threads and the checks or pipeline of the branch. When `gh` or `glab` is not logged in, it shows the login command and a Terminal button.
5. **Operation banner.** Shown during a rebase, merge or cherry-pick: "Rebase in progress…" with Terminal, Continue (rebase only) and Abort.
6. **Action bar** (see Actions), then the results of `git.pills` config actions.

### Sections

A segmented control selects one section. The choice is saved.

| Section | What it lists |
|---|---|
| Local N | Local branches in three groups: "Checked out" (current branch first, then branches in other worktrees), "Active", "Merged · safe to delete" (merged into the base branch, or the remote branch was deleted). The merged group is collapsed by default. Each row shows tags (`current`, `main checkout`, `worktree`, `N changed there`, `remote deleted`, `local only`, `merged`, `↑N`, `↓N`), the open request, the ticket chip, "visited … · committed … by …" and the last commit subject |
| Remote N | Branches of `<remote>`, newest commit first. Tag `local` when a local copy exists, the open request, the ticket chip, the date, the author and the subject |
| History | Scope "All": the last 150 commits of HEAD. Scope "This branch": the commits in `<base>..HEAD`. Each row shows the hash, the refs (HEAD, branches, tags), the subject, the author, the date and the tags `merge` and `not pushed` |
| Reflog | The last 200 moves of HEAD |
| Changes N | The commit box, then the files in groups: Conflicts, Staged, Changes, New files |
| Stash N | Only when the stash is not empty. Each entry shows the message, `stash@{n}`, the branch and the date |

A click on a commit or a reflog row lists its files. A click on a file shows its diff. A click on a changed file shows its diff. A diff shows at most 4,000 lines.

The header search filters the rows of the current section: branch name and subject, commit subject, hash, author and refs, file path, stash message.

## Actions

### Header action bar

| Action | What it does | Command |
|---|---|---|
| Fetch | Downloads new commits and branches | `git fetch --prune <remote>` |
| Pull | Fast-forwards the current branch. Disabled without an upstream | `git pull --ff-only` |
| Push | Sends the commits. Without an upstream it publishes the branch | `git push` or `git push -u <remote> <branch>` |
| Force Push… | Asks first (inline confirmation) | `git push --force-with-lease -u <remote> <branch>` |
| Rebase on `<baseName>`… | Asks first. Fetches the base, then rebases with autostash | `git fetch <remote> <baseName>`, then `git rebase --autostash <base>` |
| Update `<baseName>` | Fast-forwards the local base branch without a switch (see "Update" below). When there is no local base branch, it creates it | `git fetch <remote> <baseName>:<baseName>` |
| Stash… | Shown when there are changes. Asks for an optional message | `git stash push --include-untracked [-m <message>]` |
| Pop Stash | Shown when there are no changes and the stash is not empty | `git stash pop` |
| Terminal (icon) | Opens the terminal app from Settings in the checkout | `open -a <terminal> <path>` |
| New request (icon) | Opens the new request form under the header (see the Pull Requests page) | — |
| Open on web (icon) | Opens the branch page | GitHub `<web>/tree/<branch>`, GitLab `<web>/-/tree/<branch>` |

Operation banner:

| Button | Command |
|---|---|
| Continue | `GIT_EDITOR=true git rebase --continue` |
| Abort | `git <operation> --abort` (`rebase`, `merge` or `cherry-pick`) |
| Terminal | `open -a <terminal> <path>` |

### Local branch row

Hover buttons, the same items in the context menu (right-click):

| Action | What it does | Command |
|---|---|---|
| Switch | Switches the checkout to the branch | `git switch <branch>` |
| Stash & Switch | Shown instead when the checkout has changes. Stashes the changes, switches and restores the changes. "Switch Anyway" switches without a stash | `git stash push --include-untracked -m "DevHub: switch to <branch>"`, `git switch <branch>`, `git stash pop` |
| Update (fast-forward) | Only for a branch with a live upstream. The current branch: `git pull --ff-only`. A branch in another worktree: `git pull --ff-only` in that worktree. Any other branch: a fetch into it without a switch | `git fetch <remote> <upstream name>:<branch>` (the upstream name without the remote) |
| Build & Run… | Opens a picker for the simulator, profile and device ID, then builds the branch (in its worktree, or a new one) | see the Simulators tab |
| Build & Run on Target Now (menu) | Builds the branch on the target simulator | see the Simulators tab |
| Create Worktree | Creates a worktree for the branch (see the Worktrees page) | `git worktree add …` |
| Open Worktree in Terminal (menu) | For a branch in a worktree | `open -a <terminal> <path>` |
| Use This Checkout in Git Tab (menu) | Selects the worktree of the branch in the checkout menu | — |
| New request / Show request | Without an open request: opens the new request form under the row. Disabled when the branch is not on the remote. With an open request: shows its number and a button that opens it in the browser | — |
| Copy Name, Open on Web, Open request, Copy Link with Title (menu) | Copy and browser actions | — |
| Config actions (menu) | Actions with the `git.branchRow` placement. Inputs open under the row | see [Placements](../extensions.md#33-placements) |
| Delete… | Asks first. A "Force (-D)" box appears for a branch that is not merged | `git branch -d <branch>` or `git branch -D <branch>` |

When a stash pop after a switch fails, the changes stay in the stash and a red Recent row says so. When the switch itself fails, DevHub runs `git stash pop` to restore the changes.

"Delete all…" in the header of the merged group deletes every merged or remote-deleted branch that is not current, not checked out, not the base branch and not in `git.protectedBranches`. It asks first. Its hint names the branches that stay: the base branch and `git.protectedBranches`. A box "Force-delete branches whose remote was deleted (-D)" uses `-D` for the remote-deleted ones. Each branch runs `git branch -d <branch>` (or `-D`). The result shows how many branches git refused.

### Remote branch row

| Action | What it does | Command |
|---|---|---|
| Check Out | Switches to the local copy, or creates a tracking branch | `git switch <local>` or `git switch --track -c <local> <remote>/<branch>` |
| Build & Run on Target | Builds the branch on the target simulator | see the Simulators tab |
| Create Worktree | Creates a worktree for the local name of the branch. Disabled when a checkout of the branch exists | `git worktree add …` (see the Worktrees page) |
| Open on Web | Opens the branch page | — |
| Show request, Open request, Copy Link with Title (menu) | When the branch has an open request | — |
| New request (menu) | Opens the web page that creates a request for the branch into the base branch | — |
| Copy Name (menu) | Copies the local name | — |

### History and Reflog rows

| Action | Command |
|---|---|
| Show Files (click) | `git show --first-parent --name-status -z --format= <hash>` |
| File diff (click on a file) | `git show --first-parent --no-color --format= <hash> -- <path>` |
| Copy Hash, Copy Subject, Copy Selector (menu) | — |
| Open commit on the web (History menu) | GitHub `<web>/commit/<hash>`, GitLab `<web>/-/commit/<hash>` |

### Changes

| Action | What it does | Command |
|---|---|---|
| Stage | Adds the file to the next commit (also marks a conflict as solved) | `git add -- <path>` |
| Unstage | Keeps the change, leaves it out of the next commit | `git restore --staged -- <path>` |
| Stage All | On the Changes group, and on New files when there are no unstaged changes | `git add -A` |
| Unstage All | On the Staged group | `git reset -q` |
| Discard… / Delete… | Asks first. New file: deletes it. Unstaged or conflicted file: restores it. Staged file: restores the index and the file | `git clean -f -- <path>`, `git restore -- <path>`, `git restore --staged --worktree -- <path>` |
| Open in Editor | Opens the file in the editor from Settings | Xcode `xed <path>`, VS Code `code --goto <path>`, Cursor `cursor --goto <path>`, Zed `zed <path>`, else `open -a <editor> <path>` |
| Reveal in Finder, Copy Path, Copy File Name (menu) | — | — |
| Commit (⌘↩) | Commits the staged files. "Amend" replaces the last commit | `git commit -m <message> [--amend]` |
| Commit & Push | Commits, then pushes like the Push button | `git commit -m <message>`, then `git push` or `git push -u <remote> <branch>` |

The commit box starts with the ticket prefix of the branch (for example `ABC-123: `). Commit is disabled while there are conflicts, while the message is empty, or when nothing is staged and Amend is off.

### Stash rows

| Action | Command |
|---|---|
| Apply | `git stash apply stash@{n}` |
| Pop | `git stash pop stash@{n}` |
| Drop… (asks first) | `git stash drop stash@{n}` |

### Reads

Each refresh reads the checkout with these commands:

- `git status --porcelain=v2 --branch`
- `git rev-list --left-right --count HEAD...<base>`
- `git for-each-ref refs/heads …` and `git for-each-ref refs/remotes/<remote> --sort=-committerdate …`
- `git branch --merged <base> --format=%(refname:short)`
- `git reflog show --format=%gs%x09%ct -n 3000 HEAD` (the "visited" times)
- `git log -n 150 --decorate=full …` and `git rev-list -n 150 HEAD --not --remotes=<remote>`
- `git stash list …`, `git remote get-url <remote>`
- `git status --porcelain=v1 -z --untracked-files=all` for the Changes section

When the panel opens on the Git tab, DevHub reads the repository. When "Auto fetch" in Settings is above 0 minutes and the last fetch is older, it also runs Fetch.

## Config

| Field | Effect | Reference |
|---|---|---|
| `git.remote` | The remote of fetch, push, the remote branch list, the web links and the base branch | [`project.json`](../extensions.md#2-projectjson) |
| `git.baseBranch` | The base branch. Default `<remote>/HEAD`, else `<remote>/main` | [`project.json`](../extensions.md#2-projectjson) |
| `git.protectedBranches` | Branches that "Delete all…" never deletes | [`project.json`](../extensions.md#2-projectjson) |
| `git.commitPrefix.pattern`, `git.commitPrefix.format` | The ticket chip and the start of the commit message | [`project.json`](../extensions.md#2-projectjson) |
| `git.ticketURL` | The link of the ticket chip. Without a link the chip copies the key | [`project.json`](../extensions.md#2-projectjson) |
| `git.host.kind`, `git.host.name` | Which tool (`gh` or `glab`) reads the request line. `git.host.kind` also chooses the GitHub or GitLab path of the branch, commit and new request links | [`project.json`](../extensions.md#2-projectjson) |
| `git.pullRequests.*` | The new request form (see the Pull Requests page) | [`project.json`](../extensions.md#2-projectjson) |
| Actions with `git.pills` | Buttons in the header action bar | [Placements](../extensions.md#33-placements) |
| Actions with `git.branchRow` | Items in the context menu of a local branch row | [Placements](../extensions.md#33-placements) |

## Saved preferences

| Key | What it keeps | Default |
|---|---|---|
| `git.section` | The selected section | Local |
| `git.mergedCollapsed` | Whether the merged group is collapsed | collapsed |
| `git.historyScope` | "This branch" or "All" in History | All |
| `app.settings` | `autoFetchMinutes`, `ticketURLTemplate` (the fallback ticket link), `editor`, `terminal` | — |

The selected checkout is not saved. After a restart the tab shows the main checkout.

## Limits

- History shows at most 150 commits, Reflog 200 entries, a diff 4,000 lines.
- Continue exists only for a rebase. A merge or cherry-pick in progress shows only Abort and Terminal.
- Push on a branch with an upstream runs plain `git push`. Git then uses its own push settings, not `git.remote`.
- Commit & Push after Amend runs a normal push. When the old commit is already on the remote, the push fails and you need Force Push.
- There is no merge, cherry-pick, tag or blame action.
- The context menus of rows were checked by tests only: a headless snapshot does not open a menu (`docs/STATUS.md`).
