# DevHub

A macOS menu bar panel for daily development work: git, worktrees, simulators, logs, AI sessions and scripts. The core is generic. Project knowledge lives in `.devhub/` config files (see `docs/extensions.md`).

Status of each screen: `docs/STATUS.md`. What to build and how: `docs/SPEC.md`. Rules for contributors and AI agents: `AGENTS.md`.

## Requirements

- macOS 26 or newer
- Xcode 26 with the command line tools
- `git`

## Clone and run

```sh
git clone <repository url> DevHub
cd DevHub
Scripts/run.sh
```

`Scripts/run.sh` builds the Debug app, quits a running copy and opens the new one. DevHub is a menu bar app: look for the hammer icon in the menu bar. It has no Dock icon.

| Command | What it does |
|---|---|
| `Scripts/run.sh` | Debug build, then open it |
| `Scripts/install.sh` | Release build, copied to `/Applications/DevHub.app` and opened |
| `DevHub.command` | Double-click in Finder: runs `Scripts/run.sh` |
| `Scripts/make-launcher.sh` | Creates `DevHub Launcher.app` in this folder (an AppleScript app that runs `Scripts/run.sh`) |
| `Scripts/build.sh [Debug\|Release]` | Build only. Prints the `.app` path when the build is clean |
| `Scripts/smoke.sh` | Starts the Debug build for 3 seconds and prints `alive` or `dead` |

## Use

- Click the menu bar icon to open the panel. Right-click for Open, Pin, Settings and Quit.
- Global shortcut: ⌥⌘D (change it in Settings).
- ⌘1 to ⌘9 switch tabs. ⌘F focuses the search field. Esc clears the search, then closes the panel. ⇧⌘O shows the command output.
- The panel can be moved by its empty header space and resized from the corner grip. Its position and size are remembered.

DevHub is not sandboxed and is signed ad hoc ("Sign to Run Locally"), because it runs `git`, `xcrun` and `xcodebuild`.
