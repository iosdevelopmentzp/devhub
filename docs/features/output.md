# Output panel

The Output panel is the command log at the bottom of the panel. It is not a tab. It shows every process that DevHub starts, with its folder, its output and its exit code. Every process goes through `ShellRunner`, so nothing runs without an entry here.

Code: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Output/`, `DevHubPresentation/Shared/CommandLog.swift`, `Shared/OutputPanelState.swift`, `Shell/OutputToggle.swift`, `DevHubData/Shell/ShellRunner.swift`, `DevHubDomain/Models/CommandKind.swift`.

## What it shows

### Footer button

The footer has an "Output" button (⇧⌘O). It shows or hides the panel. Before the word it shows:

- a spinner while a command that is not a read runs;
- a red dot when one of the last 5 commands failed and was not a read.

A failed action shows an operation card at the place where it started, with the failed step, the lines that explain it and the whole output on request (see "Operations" below). The panel opens by itself on such a failure only when "Open When a Command Fails" is on in the filter menu (off by default).

### Panel

The panel is 260 points high by default. A drag on its top edge changes the height: 120 points at least, and never more than the window height minus 320 points. A double-click on the edge restores 260. The height is remembered. The header has:

- the number of shown commands;
- a search field ("Search output");
- a filter menu (funnel icon) with "Show reads", "Failed only" and "Open When a Command Fails"; the icon is filled while "Failed only" is on;
- Follow (arrow to a line, blue while on): on by default, the list scrolls to the newest command and its new lines; off, the list stays where you scrolled;
- Copy All, Clear and a button that hides the panel. Every icon has a hint.

Each entry shows:

1. A status icon: a spinner while it runs, a green check for an action, a grey check for a read, a red cross for a failure. The hint of the red cross shows the exit code.
2. The command line, for example `$ git fetch --prune origin`.
3. The start time (`14:05:09`), the working folder and the duration.
4. The last 8 lines of output, red for a failure. "… N more lines above" shows when there are more.
5. The error text when the process could not start.

While Follow is on, the list scrolls to the newest entry when an entry is added or gets new lines.

### What counts as a read

DevHub sorts each command into one of four kinds. "Show reads" off hides the reads.

| Kind | Commands | Output |
|---|---|---|
| read | `git status`, `log`, `for-each-ref`, `rev-parse`, `symbolic-ref`, `check-ref-format`, `reflog`, `rev-list`, `show-ref`, `config`, `diff`, `cherry`, `merge-base`, `ls-remote`, `remote`, `show`, `worktree list`, `stash list`, `branch` without a change flag; `xcrun simctl list`, `get_app_container`, `listapps`, `bootstatus`, `spawn … read`; `gh` and `glab` reads (see below); `xcodebuild -showBuildSettings`; `osascript` without a click; `du`, `ps`, `grep`, `plutil`, `pgrep` | shown |
| action | every other command | shown |
| secret | `security …`, `gh auth token` | replaced with "Output hidden: it contains credentials." |
| app log | `xcrun simctl spawn … log …` | replaced with "App log lines are shown in the Logs tab only." |

`gh` and `glab` follow the same rules:

1. A GraphQL query (`api graphql`) is a read. A GraphQL mutation is an action.
2. An `api` call with `-X GET` or `--method GET` is a read. An `api` call with another method is an action.
3. An `api` call without a method is a read when it sends no fields (`-f`, `-F`, `--field`, `--raw-field`, `--input`). With fields it is an action.
4. The subcommands `view`, `list`, `checks`, `diff` and `status`, for example `gh pr view`, are reads. Other subcommands are actions.

A command that streams its output (a build, a script, a bootstrap) is never shown as a read.

## Actions

| Action | What it does |
|---|---|
| Output (⇧⌘O) in the footer | Shows or hides the panel |
| Drag the top edge | Changes the height of the panel. A double-click restores the default height |
| Search output | Filters entries by the command, the output and the error text |
| Show reads (filter menu) | Also shows read-only commands |
| Failed only (filter menu) | Shows only the commands that failed: a non-zero exit code or a start error. Running commands are hidden |
| Open When a Command Fails (filter menu) | Opens the panel by itself when an action fails, as before the operation cards. Saved |
| Follow | On: the list scrolls to the newest command and its new lines. Off: the list stays where you scrolled. Turning it on scrolls to the end once |
| Copy All | Copies every shown entry as a transcript: `# in <folder>`, `$ <command>`, the output, `# exit code N`, `# <error>` |
| Save (arrow into tray) | Saves the same transcript to a file of your choice (a save panel, `devhub-output.log` by default). A Recent row says "Saved <name>" |
| Clear | Removes every finished entry. Running entries stay |
| Hide (chevron) | Hides the panel |
| Copy (entry icon) | Copies the transcript of one entry |
| Show all N lines / Show less (entry icon) | Shows the whole output of an entry, or the last 8 lines again |
| Click on the command line | Copies the command |
| Right-click an entry | Copy Command, Copy Output (when there is output), Copy Command and Output; Open in Editor (writes the transcript of the entry to `~/.devhub/scratch/output-<time>.log` and opens it in the editor from Settings); Save Output… (a save panel); Open Folder in Terminal and Reveal Folder in Finder when the command ran in a folder |

The panel runs no commands of its own.

## Operations

An operation is one action that you started. `OperationScope.current` (a Domain task-local ID) is set while the action works, and `ShellRunner` puts it into the `started` event of every command, so the command log knows which commands belong to which action. `OperationLog` (`Shared/Operations/`) keeps the running operations and the last 30 finished ones, in memory only.

Code: `DevHubPresentation/Shared/Operations/`, `Features/Operations/`, `Shared/ActionRunner.swift`, `DevHubDomain/Models/OperationScope.swift`, `DevHubDomain/Policies/FailureDigestPolicy.swift`.

| Place | Card | Started by |
|---|---|---|
| Git tab, under the header | `OperationOrigin.git` | Fetch, Pull, Push, Force Push, Rebase, Stash, Switch, Update, Delete and the other actions of `GitStore` |
| Git tab, under the commit box | `.changes` | Commit, Commit & Push, Stage, Unstage, Discard |
| Under a tile grid, a script row, the Git pills, a toolbar bar, a custom tab action | `.action(<id>)` | config actions and scripts; the `progress` line moves the bar of the card and the footer |
| Simulators, under the toolbar | `.simulators` | Boot, Shut Down, Erase, Remove Apps and the other actions of `SimulatorsStore` |
| The push panel of a simulator | `.messaging` | Send Push |
| Worktrees, under the toolbar | `.worktrees` | Fetch, Prune, Clean Finished, New (create) |
| Worktrees, under a row | `.worktree(<path>)` | Delete, Bootstrap (with Retry) |
| Pull Requests, under a row, at the top of the details pane and in a request window | `.pullRequest(<number>)` | Approve, Revoke, Ready, Draft, Update, Merge, Auto-merge, Retry and Cancel the checks (with Retry); Comment, Request Changes, a line comment, Resolve, Reply, Retry a job, the CircleCI Re-run, Cancel and Approve |

A card shows:

- while it runs: a spinner, the title, the time since the start, the steps (commands that are not reads, and reads that failed) with their duration, the last output line, the progress bar of a script and Stop for a config action;
- after a failure: "<title> failed" in red, the message, the steps with a red cross on the failed one, the lines of the failed step that explain it (`FailureDigestPolicy`: lines with `error`, `fatal`, `failed`, `rejected`, `conflict`, `denied`, `not found`, `hint:` and similar words, else the last 6 lines, at most 8 lines, colour codes removed), and Retry, Copy Error, Full Output and a close button;
- after a success with a failed step (a commit whose push failed): an orange card "<title> · a step failed" with the same failure part;
- after a success: a green line with the duration that goes away after 4 seconds.

A new operation at the same place replaces the card of the last one. Retry runs the same action again with the same inputs.

The footer shows the operations next to the build state: the title and progress of a running operation, "N running", or "N failed" in red until the list is opened. A click opens the list of this session with the same cards; the close button of a card removes it from the list, and "Clear Finished" removes every finished one.

## Config

The panel reads no `.devhub` field. Config scripts and commands appear in it like every other process: a `run.script` or `run.command` action, a header script, a source script of a custom tab, `build.command`, `run.command`, the simulator status script and the worktree bootstrap script. See [Actions](../extensions.md#3-actions) and [Script line protocol](../extensions.md#7-script-line-protocol).

## Saved preferences

| Key | What it keeps | Default |
|---|---|---|
| `output.visible` | Whether the panel is open | closed |
| `output.showsReads` | The "Show reads" box | off |
| `output.follows` | Follow: `on` or `off` | on |
| `output.opensOnFailure` | "Open When a Command Fails" in the filter menu | off |
| `output.height` | The height of the panel in points | 260 |

The entries themselves are not saved. The search text, "Failed only" and the expanded entries are not saved either.

## Limits

- The log keeps the last 300 entries and the last 4,000 lines of each entry, in memory only. "… N earlier lines dropped" shows when lines were removed.
- An argument longer than 160 characters is cut with `…`. An argument with a line break (for example a GraphQL query) shows as `'…script…'`.
- The height is capped by the window: in a small window the panel shows less than the saved height, and the saved value comes back in a taller window.
- DevHub does not change the output of a shown command. Only the secret and app log kinds are hidden.
- `xcrun simctl boot` on a booted simulator shows a red row (exit code 149) although the run continues (`docs/STATUS.md`, known gaps).
