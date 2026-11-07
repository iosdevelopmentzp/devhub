# ADR 012. Review: file groups, diff marks, side by side, the request window

Date: 2026-11-07. Status: done, 2026-11-07 (see the step log).

## Context

The owner reviewed the file part of a pull request in DevHub and asked for three things: predefined groups of files that the details offer to hide, configured per project by path and name patterns and more than one at a time; marks for what changed inside a line and a way to see a file before and after; and a richer review in the request window instead of more controls in the small panel. A fourth request came in the same session: delete a simulator from the Mac.

Before this change the details hid files only one by one (the eye-slash button, saved per project) or by the flat `git.pullRequests.hiddenFiles` list, a diff showed whole lines, and the window was the same long form as the panel.

## Decisions

### D1. File groups from config

`git.pullRequests.fileGroups` is a list of `{ "name", "patterns", "hidden" }`. `GitSettingsPolicy.fileGroups` keeps the named groups with at least one pattern, the first of two groups with the same name. `FileGroupPolicy.matches` puts each file of a request into the first group whose pattern matches its path or its name (`HiddenFilePolicy.isHidden`), and drops groups without a match. The details show one chip per matched group with the count and an eye; a click flips the group for that request (`PullRequestDetailStore.toggledGroups`, in memory). `hidden: true` starts hidden. The hidden set of a request is the union of the eye-slash files, the `hiddenFiles` patterns and the hidden groups; "Show N hidden" shows them all, and the tag of a grouped file names its group. The hide suggestion skips files that belong to a group. `hiddenFiles` stays for compatibility; the example config moves tests and project files into groups.

### D2. Changed words inside a line

`DiffLineEmphasis` (Domain) pairs the removed and added lines of one change block in order and splits each line into words, spaces and single punctuation characters. The longest common subsequence of the tokens gives the parts that differ; neighbouring changed tokens merge into one range. A pair that shares less than 40 % of its characters, or a line with more than 300 tokens, gets no marks. `DiffMapper` puts the ranges on `DiffLineModel.emphasis`, shifted past the `+` or `-`, and `DiffLine` draws them as a stronger background. The Git tab gets the marks for free because it shares the mapper.

### D3. Side by side

`DiffLayout` (`unified`, `sideBySide`) is saved under `gitlab.diffLayout` in `PullRequestsStore` and reaches the details through `PullRequestRowContext`. `SplitDiffMapper` turns the unified line models into rows: a hunk header spans both columns, a context line sits on both sides, the removed and added lines of a block pair up in order, and a missing side is an empty cell. `DiffView` draws the rows with `SplitDiffRow`, which reuses `DiffLine` with one number column per side, so line actions, threads and the comment box work as before. The picker in the files header is disabled under 600 points of details width and the diff stays unified there; the hint says so.

### D4. The request window gets a file sidebar

`PullRequestWindowView` shows a 280-point sidebar on the left: the viewed progress, a filter field, the group chips, one row per listed file (letter, name, folder, counts, open threads, changed since review, the viewed mark) and Previous and Next. A click calls `PullRequestDetailStore.revealFile`, which expands the file and sets the focus to it; the file header scrolls itself into view from a `.task(id:)` after the layout settled. The file list of the details is a plain `VStack` now: a lazy stack never materialised a file below the fold, so a scroll to it did nothing, and that also broke "Show in diff" for a far file. File headers no longer stick to the top. The window starts at 1120 × 760 and is at least 1000 × 560.

### D5. Delete a simulator

`SimulatorRepository.delete` shuts the simulator down and runs `xcrun simctl delete <udid>`. The row menu gets "Delete Simulator…" with an inline confirmation that names what goes away. Hidden for a physical device.

### D6. The operations strip replaces the floating tray

The tray of ADR 010 D2 floated over the list with whole cards and could cover most of a tab. `OperationsStrip` sits in the layout under the tab content, above the Output panel: one row per operation (`OperationStripMapper` from the card models), at most 3 rows and a "N more" line. `OperationLog.expandedID` names the one operation whose card is open; `OperationsTray` draws only that card, over the list above the strip. The chevron or a click on a row toggles it; a dismiss, a removal or Clear Finished closes it. The strip takes a fixed small height, so the list keeps its place and nothing is covered until the user asks.

## Consequences

- A project with `hiddenFiles` keeps working; the hint texts of hidden files now also name a group.
- The debug switches `DEVHUB_PULL_REQUEST_WINDOW=1`, `DEVHUB_REVEAL_FILE=<path>` and `DEVHUB_DIFF_LAYOUT=sideBySide` let a headless snapshot show the window, a file and the layout.
- The window needs 1000 points of width; a smaller saved frame grows to it.
- An operation without steps, message or output has no chevron: a success row only says what happened and goes away.

## Step log

| Commit | What |
|---|---|
| `f19941e` | D1 and D2: `FileGroupConfig`, `PullRequestFileGroup`, `FileGroupPolicy`, `PullRequestFileGroupChipMapper`, the chips and the group toggle; `DiffLineEmphasis` in `DiffMapper` and `DiffLine`; the example config. |
| `f1fbaac` | D3 and D4: `DiffLayout`, `SplitDiffMapper`, `SplitDiffRow`, the saved picker; `PullRequestFileSidebar` with its mapper, `revealFile`, the plain file list, the window size and the debug switches. |
| `9ce48c2` | D5: `SimulatorRepository.delete`, "Delete Simulator…" with the inline confirmation. |
