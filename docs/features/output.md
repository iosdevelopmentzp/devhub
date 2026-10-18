# Output panel

The Output panel is the command log at the bottom of the panel. It is not a tab. It shows every process that DevHub starts, with its folder, its output and its exit code. Every process goes through `ShellRunner`, so nothing runs without an entry here.

Code: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Output/`, `DevHubPresentation/Shared/CommandLog.swift`, `Shared/OutputPanelState.swift`, `Shell/OutputToggle.swift`, `DevHubData/Shell/ShellRunner.swift`, `DevHubDomain/Models/CommandKind.swift`.

## What it shows

### Footer button

The footer has an "Output" button (⇧⌘O). It shows or hides the panel. Before the word it shows:

- a spinner while a command that is not a read runs;
- a red dot when one of the last 5 commands failed and was not a read.

The panel opens by itself when a command fails in a way that DevHub reports as a failure (for example a failed git action, a failed push after a commit, or a script that prints an `error` directive).

### Panel

The panel is 260 points high. Its header has:

- the number of shown commands;
- a search field ("Search output");
- "Show reads";
- Copy All, Clear and a button that hides the panel.

Each entry shows:

1. A status icon: a spinner while it runs, a green check for an action, a grey check for a read, a red cross for a failure. The hint of the red cross shows the exit code.
2. The command line, for example `$ git fetch --prune origin`.
3. The working folder.
4. The duration.
5. The last 8 lines of output, red for a failure. "… N more lines above" shows when there are more.
6. The error text when the process could not start.

The list scrolls to the newest entry when an entry is added or gets new lines.

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
| Search output | Filters entries by the command, the output and the error text |
| Show reads | Also shows read-only commands |
| Copy All | Copies every shown entry as a transcript: `# in <folder>`, `$ <command>`, the output, `# exit code N`, `# <error>` |
| Clear | Removes every finished entry. Running entries stay |
| Hide (chevron) | Hides the panel |
| Copy (entry icon) | Copies the transcript of one entry |
| Show all N lines / Show less (entry icon) | Shows the whole output of an entry, or the last 8 lines again |
| Click on the command line | Copies the command |

The panel runs no commands of its own.

## Config

The panel reads no `.devhub` field. Config scripts and commands appear in it like every other process: a `run.script` or `run.command` action, a header script, a source script of a custom tab, `build.command`, `run.command`, the simulator status script and the worktree bootstrap script. See [Actions](../extensions.md#3-actions) and [Script line protocol](../extensions.md#7-script-line-protocol).

## Saved preferences

| Key | What it keeps | Default |
|---|---|---|
| `output.visible` | Whether the panel is open | closed |
| `output.showsReads` | The "Show reads" box | off |

The entries themselves are not saved. The search text and the expanded entries are not saved either.

## Limits

- The log keeps the last 300 entries and the last 4,000 lines of each entry, in memory only. "… N earlier lines dropped" shows when lines were removed.
- An argument longer than 160 characters is cut with `…`. An argument with a line break (for example a GraphQL query) shows as `'…script…'`.
- The panel has a fixed height. It cannot be resized.
- DevHub does not change the output of a shown command. Only the secret and app log kinds are hidden.
- `xcrun simctl boot` on a booted simulator shows a red row (exit code 149) although the run continues (`docs/STATUS.md`, known gaps).
