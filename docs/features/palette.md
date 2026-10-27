# Command palette

The command palette is a search box over the panel. You type a few letters and run a tab, an action, a simulator, a branch, a worktree, a request or an AI session with Return. It is not a tab.

Code: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Palette/`, `Shared/Navigator.swift`, `Shell/HeaderView.swift`, `Shell/RootView.swift`.

## What it shows

1. A text field: "Type a tab, an action, a branch, a simulator…".
2. The prompt of a config action that needs inputs or a confirmation, under the field.
3. Up to 60 items. Each item has an icon, a title, a subtitle and a section.

The palette opens only when a project is selected. A click outside the palette closes it.

### Items

The items come in this order. With an empty query the palette shows the first 60.

| Section | Items | Subtitle |
|---|---|---|
| Tabs | Every tab of the tab bar, the custom tabs, and Settings | "Show the tab" |
| Projects | "Switch to project <name>" for every project except the selected one | The shortcut (⌃⌘1 to ⌃⌘9) and the path |
| Actions | "Keep Mac awake" or "Let the Mac sleep" (after the AI sessions, before Settings) | The state of the switch |
| Actions | Every built-in action, then every config action whose file is executable and whose `when` condition matches | The subtitle of the action, else its file name, or "Built-in action" |
| Simulators | "Build & Run on <simulator>" for each simulator, and "Make <simulator> the target" for each one that is not the target | booted or shut down |
| Branches | For each local branch except the current one: "Switch to <branch>", "Build & Run <branch>", "Create a worktree for <branch>" | — |
| Worktrees | For each linked worktree: "Open worktree <name>", "Build & Run worktree <name>" | The path |
| Pull requests | The requests that the Pull Requests tab has loaded: `#12 <title>` or `!12 <title>` | `<source> → <target> · <author>` |
| AI sessions | "Resume <session>" for up to 20 sessions in the current scope of the AI tab whose folder still exists. Favorite sessions come first, with a star | "Favorite" for a favorite, the provider and the folder |

### Search

1. The query is split into words.
2. An item matches when every word is in its title, subtitle or section (case does not matter).
3. Items whose title starts with the first word come first. Then items whose title contains the first word. Then the rest. Inside each group the order above stays.

## Actions

### Keys

| Key | What it does |
|---|---|
| ⌘K, or the ⌘ button in the header | Opens the palette with an empty query, or closes it |
| ↓ / ↑ | Moves the highlight |
| Return | Runs the highlighted item |
| Esc | Closes the palette |

### What each item runs

| Item | What it does | Command |
|---|---|---|
| A tab | Shows the tab | — |
| Settings | Shows Settings | — |
| Switch to project `<name>` | Selects the project, like the project menu in the header | — |
| Keep Mac awake, Let the Mac sleep | Turns the Home switch on or off | — |
| A built-in action | The same as the Home tile (see the Home page) | see the Home page |
| A config action | Runs the action. When it has inputs or `confirm`, the prompt opens in the palette, and the palette stays open until you run or cancel | the `run` of the action |
| Build & Run on `<simulator>` | Builds and runs on that simulator | see the Simulators tab |
| Make `<simulator>` the target | Makes it the target of the run bar | — |
| Switch to `<branch>` | Switches the checkout of the Git tab. When the checkout has local changes, DevHub does not switch: it shows the Git tab and a toast that asks you to use Switch or Stash & Switch in the branch row | `git switch <branch>` |
| Build & Run `<branch>` | Builds the branch on the target simulator (uses or creates a worktree) | see the Simulators tab |
| Create a worktree for `<branch>` | Creates a worktree and runs the bootstrap when needed | see the Worktrees page |
| Open worktree `<name>` | Opens the folder in Finder | `NSWorkspace.open` |
| Build & Run worktree `<name>` | Builds that worktree on the target simulator | see the Simulators tab |
| A request | Shows the Pull Requests tab and opens the request | — |
| Resume `<session>` | Opens the terminal app from Settings in the session folder and runs the resume command of the session | the `copilot` or `claude` resume command |

After a run the palette closes, except for a config action that waits for its prompt.

## Config

| Field | Effect | Reference |
|---|---|---|
| Actions in every layer | Every config action is in the palette when its `when` condition matches. The placement `palette` is always added | [Actions](../extensions.md#3-actions), [Placements](../extensions.md#33-placements) |
| Header scripts | Each executable script is an action | [Scripts with a header](../extensions.md#4-scripts-with-a-header) |
| `inputs`, `confirm` | The prompt in the palette | [Inputs](../extensions.md#32-inputs) |
| Custom tabs | One item per tab | [Custom tabs](../extensions.md#8-custom-tabs) |

A script that should appear only in the palette uses `# devhub: placements = palette`.

## Saved preferences

The palette saves nothing. The query is empty each time the palette opens. A config action run from the palette updates `configActions.lastRun` and `configActions.inputs` like on Home.

## Limits

- At most 60 items are shown. Type more letters to find the rest.
- The palette does not list a script without the executable bit. Home shows it with the "Run chmod +x" hint.
- The requests are the ones that the Pull Requests tab has loaded for its current scope and state. A request outside that list is not in the palette.
- Only local branches are listed. Remote branches without a local copy are not.
