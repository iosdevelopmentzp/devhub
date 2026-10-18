# DevHub

A macOS menu bar panel for daily development work: git, worktrees, pull and merge requests, simulators, Build & Run, logs, a network mock server with GraphQL support, AI sessions and scripts. The core is generic. Project knowledge lives in `.devhub/` config files (see `docs/extensions.md`).

## Documentation

| File | What it explains |
|---|---|
| `docs/features/*.md` | one page per tab: what it shows, every action and the command it runs, config, limits |
| `docs/extensions.md` | the `.devhub/` config schema |
| `docs/examples/devhub/` | a complete `.devhub` folder that uses every field |
| `docs/STATUS.md` | where the project stands, decisions, known gaps |
| `docs/ARCHITECTURE.md` | the module contract |
| `docs/testing.md` | how to run and write tests |
| `docs/adr/` | design decisions: the rewrite plan (001), config (002), code hosts (003), launch identities and network (004) |
| `AGENTS.md` | rules for contributors and AI agents |

## Requirements

- macOS 26.4 or newer
- Xcode 26 with the command line tools
- `git`; `gh` for GitHub pull requests, `glab` for GitLab merge requests
- Optional: `claude` and `copilot` for the AI tab, `python3` for some example scripts

Settings → Doctor shows which tools DevHub finds and how to install the missing ones.

## Run

```sh
Scripts/build.sh
Scripts/test.sh
Scripts/run.sh
```

`Scripts/run.sh` builds the Debug app, quits a running copy of this build and opens the new one. DevHub is a menu bar app: look for its icon in the menu bar. It has no Dock icon. ## First project in two minutes

1. Open the panel and choose **Add Project**. Pick the folder of a git repository with an `.xcodeproj` or `.xcworkspace`.
2. Open **Settings** (the gear in the header) and choose **Create .devhub Example**. DevHub writes a `.devhub` folder with a project file, actions, scripts and a custom tab into the project.
3. Open **Home**. The example scripts are there. Edit the files in `.devhub`: DevHub reads them again on save.

The config schema is in `docs/extensions.md`.

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
- ⌘1 to ⌘8 switch the built-in tabs; ⌘9 opens the first custom tab. ⌘F focuses the search field. ⌘K opens the command palette. Esc clears the search, then closes the panel.
- While the panel is closed, DevHub posts a macOS notification for a finished or failed Build & Run and for new review requests. The menu bar icon shows a red dot after a failed build.
- Move the panel by its empty header space and resize it from the corner grip. Its position and size are remembered.

DevHub is not sandboxed and is signed ad hoc ("Sign to Run Locally"), because it runs `git`, `xcrun` and `xcodebuild`.
