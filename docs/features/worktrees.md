# Worktrees

The Worktrees tab (⌘4) lists the git worktrees of the project. A worktree is a second folder with its own checkout of the same repository. You can work on two branches at the same time without a switch.

Code: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Worktrees/`, `DevHubData/Git/ShellWorktreeRepository.swift`, `DevHubDomain/UseCases/CreateWorktreeUseCase.swift`, `RemoveWorktreeUseCase.swift`, `CleanFinishedWorktreesUseCase.swift`.

## What it shows

### Toolbar

- The number of worktrees.
- A `base <branch>` tag: the base branch for new worktrees and for the merged check.
- A `DerivedData <size>` tag: the total Xcode DerivedData of the linked worktrees. The main checkout is not counted.
- Buttons: Fetch, Prune N (only when folders are missing), Clean Finished (N)…, New….

### List

The rows are in four groups:

| Group | What is in it |
|---|---|
| Main checkout | The project folder |
| In progress | Linked worktrees that are not finished, newest activity first |
| Finished · merged or remote branch deleted | The branch is merged into the base branch, or its remote branch was deleted |
| Missing folder | Git knows the worktree, but its folder is gone |

Each row shows:

1. An icon: house (main), branch (in progress), seal (finished), question mark (missing).
2. The branch name and tags: `main`, `build source` (the run bar builds this checkout), `locked`.
3. The path (relative to the main checkout when it is inside it) and the short hash.
4. Status tags: `clean` or `N changed` or `folder missing`, `merged into <base>` or `remote branch deleted` or `not pushed`, `↑N ↓N`, the DerivedData size.
5. `needs bootstrap` (orange) when the bootstrap marker exists in the main checkout but not in this worktree. A click runs the bootstrap script. While it runs, the row shows "Running <script>…".
6. The time and subject of the last commit.

The row of the build source has a highlighted background. The header search filters by name, path and last commit subject.

## Actions

### Toolbar

| Action | What it does | Command |
|---|---|---|
| Fetch | Downloads branches, then reads the list again | `git fetch --prune <remote>` |
| Prune N | Removes the entries of worktrees whose folder is gone | `git worktree prune` |
| Clean Finished (N)… | Asks first. Removes every finished worktree that is clean, not locked, not missing and not the build source. For each one it removes the worktree, its DerivedData folder and its local branch. The report counts only the DerivedData that was really removed | see "Delete" below, with both boxes on |
| New… | Opens a field for a branch name. Create makes the worktree (see below) | — |

### Create a worktree

New…, the Git tab, the Pull Requests tab and the command palette all use the same steps:

1. DevHub removes a `<remote>/` prefix from the name and checks it: `git check-ref-format --branch <branch>`.
2. The folder is `git.worktrees.folder/<branch>` when the field is set. Without it, the folder is a sibling of the project: `<project folder>-<branch>`. A `/` in the branch name becomes `-`.
3. DevHub runs one of three commands in the main checkout:

   | Case | Command |
   |---|---|
   | A local branch with this name exists | `git worktree add <path> <branch>` |
   | Only `<remote>/<branch>` exists | `git worktree add --track -b <branch> <path> <remote>/<branch>` |
   | Neither exists | `git worktree add --no-track -b <branch> <path> <base>` |

4. DevHub copies each file of `git.worktrees.include` from the main checkout when it is missing in the new worktree.
5. DevHub runs the bootstrap script when the new worktree needs it, or always when `git.worktrees.bootstrap` is set without `git.worktrees.bootstrapMarker`.

### Bootstrap

The bootstrap script runs inside the worktree:

- an executable file runs as is: `<worktree>/<script>`;
- another file runs with zsh: `/bin/zsh <worktree>/<script>`.

The output goes to the Output panel. A non-zero exit code shows a red Recent row "Bootstrap failed".

### Row actions

Hover buttons, the same items in the context menu (right-click):

| Action | What it does | Command |
|---|---|---|
| Build & Run… | Opens the simulator, profile and device ID picker, then builds this worktree | see the Simulators tab |
| Build & Run on Target Now (menu) | Builds this worktree on the target simulator | see the Simulators tab |
| Run Tests | Runs the tests of this worktree on the target simulator. See "Run tests" below | `xcodebuild … test` |
| Use as Build Source / Stop Using as Build Source (menu) | Makes the run bar build this checkout, or the main checkout again | — |
| Open in Finder | — | `NSWorkspace.open` |
| Open in Xcode | Opens `xcode.container` in the worktree, else the first `.xcworkspace`, else the first `.xcodeproj` | `open -a Xcode <container>` |
| Open in Terminal | Opens the terminal app from Settings | `open -a <terminal> <path>` |
| Start AI Session Here → Claude Code, Copilot CLI (menu) | Opens the terminal app from Settings in the worktree and starts a new session ([AI](ai.md)) | `claude` or `copilot` |
| Copy Path, Copy Branch Name (menu) | — | — |
| Run `<bootstrap script>` (menu) | When `git.worktrees.bootstrap` is set | see "Bootstrap" |
| Config actions (menu) | Actions with the `worktrees.row` placement. They get `DEVHUB_WORKTREE_PATH`, `DEVHUB_BRANCH` and `DEVHUB_ROW_ID` (the path). Inputs open under the row | see [Placements](../extensions.md#33-placements) |
| Delete Worktree… | Not for the main checkout or a missing folder. See below | — |

### Run tests

The checkmark button (hover) and "Run Tests" (menu) run the tests of the worktree. Not for a missing folder or a `kind: command` project. One run per worktree at a time; other worktrees can test at the same time.

1. DevHub boots the target simulator of the run bar. Without a target, a red Recent row says "No simulator for the tests".
2. It runs `xcodebuild <-workspace|-project> <container> -scheme <scheme> -configuration <configuration> -destination id=<udid> -resultBundlePath <bundle> test` inside the worktree, with the scheme and configuration of the run bar. The container is `xcode.container`, else the first `.xcworkspace`, else the first `.xcodeproj` of the worktree. The bundle goes to `<temp>/DevHub-tests/<scheme>-<timestamp>.xcresult`; the newest ten bundles are kept.
3. A panel under the row shows the current step (build steps, then "Running tests"), live counts, and after the run: `N passed · M failed · K skipped · <time> · <simulator>`. Each failed test shows its name, `File.swift:line` and the message; a click opens the file at that line in the editor from Settings. When the build broke and no test ran, the panel says "Tests did not run" with the compiler errors.
4. "Run Again" starts the same run; "Open Results in Xcode" opens the `.xcresult` bundle; "Fix with AI" (after a run with failed tests or compiler errors) writes them into a prompt file (`~/.devhub/prompts/fix-tests-<worktree>.md`) and starts Claude Code or Copilot CLI in the terminal inside the worktree with the command from `ai.commands`; the stop button cancels (`xcodebuild` gets SIGTERM); the × button hides the panel.
5. The full `xcodebuild` output is in the Output panel. A Recent row and a notification (when the panel is closed) report the result.

DevHub reads both XCTest lines (`Test Case '-[Module.Suite test]' passed (0.1 seconds).`, `/path/File.swift:42: error: -[…] : message`) and Swift Testing lines (`✔ Test "name" passed after 0.1 seconds.`, `✘ Test "name" recorded an issue at File.swift:42:9: message`). Swift Testing prints only the file name; DevHub finds the file in the worktree (hidden folders, `Pods`, `Carthage`, `DerivedData`, `build` and `node_modules` are skipped). An unresolved file shows without a link.

### Delete

Delete asks first, inside the row. The confirmation shows warnings:

- "N uncommitted changes will be lost" when the worktree has changes;
- "The branch was never pushed" or "N commits are not pushed";
- "The worktree is locked".

It has two boxes:

| Box | Default | Command |
|---|---|---|
| Delete DerivedData (size) | on (disabled when no DerivedData folder is found) | removes the folder inside the Xcode DerivedData folder |
| Delete branch `<branch>` | on for a finished worktree, off for the others | `git branch -d <branch>` (refuses a branch that is not fully merged) |

The worktree itself is removed with `git worktree remove <path>`. A worktree with changes or a lock gets `git worktree remove --force --force <path>`.

DevHub finds the DerivedData folder of a checkout by the `WorkspacePath` value in `info.plist` of each folder under `~/Library/Developer/Xcode/DerivedData` (or the custom location set in Xcode). It measures the size with `du -sk <folder>`.

### Reads

- `git worktree list --porcelain`
- `git symbolic-ref --short refs/remotes/<remote>/HEAD` (the base branch when `git.baseBranch` is not set)
- `git branch --merged <base> --format=%(refname:short)`
- `git for-each-ref --format=… refs/heads` (upstream, ahead, behind, gone)
- for each worktree: `git status --porcelain` and `git log -1 --format=%s%n%ct`

DevHub reads the list each time the panel opens, after a branch change in another tab, and after a config change to the git settings.

## Config

| Field | Effect | Reference |
|---|---|---|
| `git.remote` | The remote of Fetch and of the remote branch check | [`project.json`](../extensions.md#2-projectjson) |
| `git.baseBranch` | The base of new branches and of the merged check | [`project.json`](../extensions.md#2-projectjson) |
| `git.worktrees.folder` | Where new worktrees go | [`project.json`](../extensions.md#2-projectjson) |
| `git.worktrees.include` | Files copied from the main checkout into a new worktree | [`project.json`](../extensions.md#2-projectjson) |
| `git.worktrees.bootstrap` | The script that prepares a new worktree | [`project.json`](../extensions.md#2-projectjson) |
| `git.worktrees.bootstrapMarker` | The file that shows that a worktree is prepared | [`project.json`](../extensions.md#2-projectjson) |
| Actions with `worktrees.row` | Items in the row context menu | [Placements](../extensions.md#33-placements) |
| `refresh: ["worktrees"]` | Reads the list again after an action | [Actions](../extensions.md#3-actions) |

## Saved preferences

The Worktrees tab saves no preferences of its own. It uses `terminal` from `app.settings` for Open in Terminal. The build source mark comes from the run bar of the Simulators tab.

## Limits

- `git.worktrees.include` copies plain paths only. An entry with `*` is skipped. A file that already exists in the worktree is not replaced.
- Run tests uses the scheme of the run bar. A separate test scheme can be picked there first; there is no `xcode.testScheme` field yet. There is no "run only the failed tests" button.
- `needs bootstrap` needs three things: the script exists in the worktree, the marker exists in the main checkout, and the marker is missing in the worktree.
- The confirmation text of Clean Finished says that the local branches are removed. `git branch -d` still refuses a branch that is not fully merged; the report then says "branch kept".
- The context menus of rows were checked by tests only (`docs/STATUS.md`).
