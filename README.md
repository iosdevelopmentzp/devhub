# DevHub

A macOS menu bar panel for daily development work: git, worktrees, merge requests, simulators, Build & Run, logs, a network mock server, AI sessions and scripts. The core is generic. Project knowledge lives in `.devhub/` config files (see `docs/extensions.md`).

Where the project stands: `docs/STATUS.md`. The current rewrite: `docs/adr/001-port-from-main-devhub.md`. The module contract: `docs/ARCHITECTURE.md`. Rules for contributors and AI agents: `AGENTS.md`.

## Requirements

- macOS 26.4 or newer
- Xcode 26 with the command line tools
- `git`; `glab` for merge requests, `gh` for pull requests (later milestone)

## Run

```sh
Scripts/build.sh
Scripts/test.sh
Scripts/run.sh
```

`Scripts/run.sh` builds the Debug app, quits a running copy of this build and opens the new one. DevHub is a menu bar app: look for its icon in the menu bar. It has no Dock icon. On the first launch, add a project: the folder of a git repository.

| Command | What it does |
|---|---|
| `Scripts/build.sh [Debug\|Release]` | Layer check, anonymity check, then the build. Prints the `.app` path when everything is clean |
| `Scripts/test.sh` | Runs the package tests and prints one summary line |
| `Scripts/run.sh` | Debug build, then open it |
| `Scripts/smoke.sh` | Starts the Debug build for 3 seconds and prints `alive` or `dead` |
| `Scripts/install.sh` | Release build, copied to `/Applications/DevHub.app` and opened |
| `DevHub.command` | Double-click in Finder: runs `Scripts/run.sh` |
| `Scripts/make-launcher.sh` | Creates `DevHub Launcher.app` in this folder (an AppleScript app that runs `Scripts/run.sh`) |

## Use

- Click the menu bar icon to open the panel. Right-click for Open, Pin, Settings and Quit.
- Global shortcut: ⌥⌘D (change it in Settings).
- ⌘1 to ⌘8 switch tabs. ⌘F focuses the search field. Esc clears the search, then closes the panel.
- Move the panel by its empty header space and resize it from the corner grip. Its position and size are remembered.

DevHub is not sandboxed and is signed ad hoc ("Sign to Run Locally"), because it runs `git`, `xcrun` and `xcodebuild`.
