# ADR 010. Search in the tab, the operations tray, the checkout badge

Date: 2026-11-07. Status: accepted.

## Context

Three things in the panel were hard to use:

1. The search field sat in the header, far from the list it filters. On the Simulators tab the run bar and the toolbar stood between them.
2. An operation card appeared inline under a header, a toolbar or a row. When a command started, the card pushed the content below it down, and the content jumped again when the card grew or went away.
3. The build source and the Git checkout were a small menu label. A build from a worktree or a branch, and Git actions in a worktree, looked the same as the main checkout.

## Decisions

### D1. The search field in the toolbar of each tab

`TabSearchField` (Presentation `Shell/`) wraps `SearchField` with the prompt of the selected tab (`TabItemMapper`), the text of `ProjectSession` and the ⌘F shortcut. Each tab places it in its toolbar, next to the list it filters: Git in the section bar, Pull Requests, Worktrees, Simulators, Logs, Network, AI, Utils and Notifications in their toolbars, Home next to the "Quick actions" title. A custom tab gets a toolbar with the number of sections and the field. The header keeps the project menu, the palette, the pin, the bell and Settings. The "Showing only items that match" bar is gone: the field itself shows the text and its clear button. One text per tab, saved on a tab switch, as before. The AI, Pull Requests and Worktrees toolbars wrap to two rows when the panel is narrow (`ViewThatFits`), so no button is cut.

### D2. One operations tray per window

`OperationsTray` (`Features/Operations/`) shows every operation that is not dismissed, in start order, as `OperationCard`s in a column at the bottom of the tab, over the list and above the Output panel (an overlay in `RootView`). It floats, so nothing below it moves. Several operations at once are several cards. When the cards need more than 45 % of the panel height, the tray scrolls. A success hides after 4 seconds; a failure stays until its close button; a new operation at the same origin hides the finished card of the last one (`OperationLog.start`, as before). A request window shows a tray with the operations of that request only. `OperationSlot` and every inline placement are gone. "Remove Apps from All" became an operation with progress and Stop, so the Simulators toolbar no longer grows while it runs. A custom script reports its state with the `progress` line, as before; the hint card on Home shows it.

Why a tray and not the Output panel: the panel is the transcript of every command; a card is one action with its steps, digest and Retry. The tray sits right above the panel, so both are in one place.

### D3. The checkout badge

`CheckoutBadgeMapper` builds one `CheckoutBadgeModel` for the build source of the run bar and for the checkout menu of the Git header: gray "Main checkout · <branch>" (house) for the main checkout; orange "Worktree · <name>" (stack) or "Branch · <name> · new worktree on run" (branch) for anything else; orange with the path when the checkout is not in the worktree list. `CheckoutBadge` draws it as the label of the menu. Orange means "not the main checkout", so it stands out at a glance. The badge is the first element of the run bar options, which wrap to two rows when the panel is narrow.

## Consequences

- A card is no longer next to the row it belongs to. The title names the subject (the branch, the worktree, the request, the simulator).
- `BuildSourceMenuModel` lost `label`, `icon` and `hint`; `GitHeaderMapper.checkoutLabel` is gone.
- The Git section bar shows its tip as a hint of the picker instead of a visible text.

## Step log

| Commit | What |
|---|---|
