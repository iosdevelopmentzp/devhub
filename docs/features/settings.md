# Settings tab

The Settings tab holds the app settings, the project list, the config folders and the Doctor check.

Source: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Settings/`, `DevHubPresentation/Shared/SettingsStore.swift`, `ProjectSession.swift`, `Notifier.swift`, `DevHubDomain/Models/AppSettings.swift`, `DevHubDomain/Policies/DoctorPolicy.swift`, `DevHubDomain/UseCases/CheckToolsUseCase.swift`.

## What it shows

The tab is one form with these sections, from top to bottom:

1. General
2. Notifications
3. AI usage
4. Pull Requests (or Merge Requests on GitLab)
5. Projects
6. Project config
7. Global config folder
8. Tools
9. Tickets
10. Git
11. Doctor
12. Disk
13. About

Each section is explained under "Actions".

## Actions

### General

| Control | What it does |
|---|---|
| Launch at login | Registers or removes DevHub as a login item (`SMAppService.mainApp`). An error shows in orange under the switch. When macOS needs approval, DevHub says so and opens System Settings → General → Login Items |
| Window | "Menu bar panel" (default): DevHub opens under the menu bar icon and closes on a click outside it. "Normal window": one window with a title bar, a Dock icon and a main menu (DevHub, File, Edit, Window). The close button and ⌘W hide it, DevHub keeps running. The menu bar icon, the global shortcut and the Dock icon show it on the current desktop. It opens at launch when it was open when DevHub quit. The change applies at once |
| Show Dock icon | Panel mode only. On: DevHub shows a Dock icon (activation policy `regular`). Off: menu bar only (`accessory`). Window mode always shows the Dock icon |
| Open DevHub from anywhere | The global shortcut: Off, ⌥⌘D (default), ⌃⌥Space, ⌃⌥D. Panel mode: opens the panel, or brings the pinned window to the front. Window mode: shows the window on the current desktop, or hides it when it is in front |

### Notifications

| Control | What it does |
|---|---|
| Notify while the panel is closed | The main switch, on by default. Off: no notification of the kinds below, except the script ones. Every event still goes to the Notifications screen (the bell) and to Recent on Home |
| Builds | A build or a launch finished, or the build failed. A click on the notification opens the run bar in the Simulators tab |
| Test runs | The tests of a worktree finished or did not run. A click opens the Worktrees tab |
| Pull Requests waiting for your review | The number of requests that wait for your review went up. A click opens that list |
| Reviews of my pull requests | Someone approved your request or asked for changes. A click opens the request |
| Checks of my pull requests | The checks or pipeline of your request turned to failed. A click opens the request |
| Comments on my pull requests | Someone else commented on your request ("sam commented on #12"). Your own comments are silent. A click opens the request |
| My pull requests merged or closed | Your request was merged, or closed without a merge. A click opens the request |
| Watched pull requests | A request you watch got an approval, a request for changes, failed checks, a new comment, or was merged or closed. A click opens the request. |
| Inbox: mentions and requests on GitHub | Someone mentioned you, asked for your review or approval, assigned you, or commented where you take part, on GitHub. A click opens the request or the Inbox. |
| Script notifications | A script printed a `notify` line. It shows even while the panel is open and when the main switch is off |
| Permission | Shows "Not asked yet", "Allowed" or "Denied". **Allow Notifications** asks macOS for permission. When denied, allow DevHub in System Settings → Notifications |

Rules of the notifications:

1. A notification needs the macOS permission.
2. Every kind except the script one appears only while the panel is closed and the main switch is on. A kind with its switch off never appears; its events still go to the Notifications screen.
3. A script line `@devhub {"notify": "Title", "body": "…"}` posts a notification even when the panel is open or the main switch is off, unless "Script notifications" is off.
4. The menu bar icon shows a circle while a build runs. After a failed build while the panel is closed, it shows a red dot until you open the panel.
5. Changes of your own requests come from the read of the open requests every 5 minutes, or every 2 minutes while the panel is closed ([Pull Requests](pull-requests.md#other-places-that-use-the-same-data)). A refresh after an action of yours in DevHub (a comment, an approval) updates the baseline without a report.

6. A click on a notification opens DevHub at the place of the event: a request, the review list, the Worktrees tab or the run bar. Every event is also in the Notifications screen (the bell in the header, [Notifications](notifications.md)).

### AI usage

| Control | What it does |
|---|---|
| Show usage for | "Claude and Copilot" (the default), "Claude only" or "Copilot only". The usage strip and the menu bar show only the chosen providers, and DevHub reads only their usage |
| Show usage strip at the top | Shows the usage strip above the panel header ([AI](ai.md#usage-strip)) |
| Show session usage in the menu bar | Shows the used percent of the first limit of the first chosen provider next to the menu bar icon |
| Write with AI and Explain use | Claude Code (the default) or Copilot CLI: the tool of "Write with AI" in the commit box and the new request form, and of "Explain" in the request details. The arrow next to each button picks the other tool for one run. `ai.textCommands` in `project.json` changes the command ([Pull Requests](pull-requests.md#write-with-ai-and-explain)) |

### Pull Requests

The title follows the code host: "Pull Requests" for GitHub, "Merge Requests" for GitLab.

| Control | What it does |
|---|---|
| Show the number of requests waiting for your review in the menu bar | Shows a count next to the menu bar icon, for example "3 PR" on GitHub or "3 MR" on GitLab. It counts open requests by other people, not drafts, that you have not approved. DevHub checks every 5 minutes |
| Remember what I reviewed | On by default. DevHub saves a fingerprint of the diff of each file when you approve, comment, ask for changes or mark every file as viewed, and shows the files that changed since in the details. Viewed marks stay until a file changes. Off removes everything it saved. See [Pull Requests](pull-requests.md#changed-since-your-review) |

### Projects

One row per project. The selected project has a filled indigo icon. A `launch identity` tag shows when the selected project has `launch.identity`.

| Action | What it does |
|---|---|
| Scheme field | The scheme Build & Run starts with. The run bar can switch it. A change applies at once |
| Bundle ID field | The fallback bundle ID for uninstall, deep links, push and the log process lookup. `xcode.bundleIDs`, `xcode.bundleID` and the last launch from DevHub come first ([Device identity](device-identity.md#the-bundle-id)). A change applies at once |
| Xcode picker | The Xcode of this project: "Default" (the `xcode.developerDir` of `.devhub/project.json`, else the Xcode of `xcode-select`) or one of the Xcode apps that Spotlight finds (`mdfind kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'`, newest first, read from `Contents/version.plist`; the Xcode of `xcode-select` and the chosen one are read from their `version.plist` when Spotlight does not list them). DevHub passes the choice as `DEVELOPER_DIR` to `xcodebuild`, `xcrun` and `xed`, and opens that Xcode with `open -a`. The selected project shows a line "Builds use …". Saved with the project. The run bar of the Simulators tab shows the chosen Xcode as a tag |
| Re-detect (circular arrows) | Finds the scheme and the bundle ID again in the project files, saves them and shows them in a toast |
| Remove (minus) | Asks inside the row, then removes the project from DevHub. The folder stays on disk. The last project cannot be removed |
| Add Project… | Opens a folder picker that starts in `~/Documents/Projects`. Adding a folder that is already in the list selects it |

How DevHub finds the scheme and the bundle ID (`XcodeProjectDetector`):

1. **Container:** the first `.xcworkspace` in the folder, else the first `.xcodeproj`.
2. **Scheme:** the first scheme name in sorted order, from `xcshareddata/xcschemes` and `xcuserdata/*/xcschemes`. For a workspace, the `.xcodeproj` files next to it count too. Without schemes: the container name, else the folder name.
3. **Bundle ID:** the shortest `PRODUCT_BUNDLE_IDENTIFIER` in the `project.pbxproj` files of the folder. DevHub skips values that contain `$`, `Tests`, `Extension`, `Widget`, `Intents`, `Clip` or `Notification`.

The project name is the folder name. `.devhub/project.json` can override the scheme and the bundle ID (`xcode.scheme`, `xcode.bundleID`).

### Project config

| Item | What it does |
|---|---|
| Layers | Lists the three config folders of the selected project with their paths: user, project and global. A folder that does not exist shows "(none)" |
| Create .devhub Starter | Writes `.devhub/project.json` into the selected project with what DevHub found: `name`, `kind`, `xcode.scheme` and `xcode.bundleID` (only for an Xcode project), `git.remote`, `git.host.kind` (after the first read of the remote) and `git.baseBranch`. Then it opens the file in the editor from Settings. Nothing is written when the file exists |
| Create .devhub Example | Writes an example `.devhub` folder into the selected project: `project.json`, actions, scripts and a custom tab. When the folder exists, nothing is written and the error shows in a toast |
| Reveal .devhub Folder | Opens the first config folder that exists, in this order: project, user, global. Without one, a toast says "No .devhub folder yet" |

Both buttons are off when there is no project.

### Global config folder

| Item | What it does |
|---|---|
| Path | Shows `~/.devhub`. A click copies the full path |
| Reveal | Opens the folder in Finder. When the folder does not exist, the row shows "not created" instead |

Actions, scripts and tabs in this folder appear in every project. An item with the same `id` in a project folder wins.

### Tools

| Control | Choices | Used by |
|---|---|---|
| Editor | Xcode, Cursor, VS Code, Zed | "Edit" on script rows in Home and custom tabs |
| Terminal | Terminal, iTerm2, Ghostty, Warp | Resume in the AI tab, "Fix threads with AI", `terminal` actions, and Open Terminal |

### Tickets

| Control | What it does |
|---|---|
| Ticket link | A URL with `{key}`, for example `https://tracker.example.com/browse/{key}`. A ticket chip opens it with the key in place of `{key}`. Without a link, a click on the chip copies the key |

A project can set its own pattern and link with `git.commitPrefix` and `git.ticketURL`.

### Git

| Control | What it does |
|---|---|
| Fetch when the Git tab opens | Never (default), or "If older than 5, 15, 30 or 60 min". DevHub runs Fetch once when the Git tab opens and the last fetch is older than this |

### Doctor

The Doctor section checks the tools that DevHub runs. It runs when the section appears, and on **Check Again**.

1. DevHub searches for each tool in `/opt/homebrew/bin`, `/usr/local/bin`, `~/.local/bin`, then in its own `PATH`.
2. DevHub runs the version command with a 5 second limit and shows the first version number in the output.
3. A found tool shows its version and path (click to copy). A missing tool shows "missing" in orange and **Copy Install Command**. A tool without a version also offers the install command. A tool with a minimum version (`circleci`: 1) shows "<version>, needs 1 or newer" in orange with the upgrade command.

| Tool | Version command | Purpose | Install command |
|---|---|---|---|
| `git` | `git --version` | Git tab, worktrees, branches | `xcode-select --install` |
| `xcodebuild` | `xcodebuild -version` | Build & Run | Install Xcode from the App Store, then `sudo xcode-select -s /Applications/Xcode.app` |
| `xcrun` | `xcrun simctl help` (shows "simctl") | Simulators, logs, launches | `sudo xcode-select -s /Applications/Xcode.app` |
| `gh` | `gh --version` | GitHub pull requests | `brew install gh && gh auth login` |
| `glab` | `glab --version` | GitLab merge requests | `brew install glab && glab auth login` |
| `circleci` | `circleci version` | CircleCI workflows, jobs and flaky tests (version 1 or newer) | `brew install circleci && circleci auth login`; an old version: `brew upgrade circleci` |
| `copilot` | `copilot --version` | Copilot CLI sessions | `npm install -g @github/copilot` |
| `claude` | `claude --version` | Claude Code sessions and AI review | `npm install -g @anthropic-ai/claude-code` |
| `python3` | `python3 --version` | Scripts of the example `.devhub` folder | `xcode-select --install` |
| `ffmpeg` | `ffmpeg -hide_banner -version` | Utils: compress videos (ffmpeg and ffprobe with libx264) | `brew install ffmpeg` |

Two permission rows follow:

| Row | What it shows | Action |
|---|---|---|
| Accessibility | "allowed" or "not allowed". Run & Attach needs it to click Debug → Attach to Process in Xcode | **Open System Settings** asks macOS for the permission |
| Notifications | "allowed", "denied" or "not asked" | none here; see the Notifications section |

A tool that a project does not use can stay missing.

### Disk

The first time the Settings tab opens, DevHub lists the Xcode, simulator and package manager folders that every Mac has, then measures each one with `du -sck` (four at a time). "Scan Again" reads everything again. The header shows the total. Each line shows its size and a "Delete…" button that asks first, inside the line: the title names the size, the warnings say what you lose. A delete runs as an operation card under the header, with Retry after a failure, and the line goes away when it worked. Nothing goes to the Trash.

| Line | What it is | Delete runs |
|---|---|---|
| DerivedData of deleted projects | DerivedData folders whose `info.plist` names a `WorkspacePath` that no longer exists | `rm -rf -- <folders>` |
| Unavailable simulators | Simulators whose runtime is not installed (`xcrun simctl list devices unavailable -j`); the size is the sum of their `dataPathSize` | `xcrun simctl delete unavailable` |
| Archives | The folders in `~/Library/Developer/Xcode/Archives`. They keep the dSYM files of shipped builds | `rm -rf -- <folders>` |
| Device support files | The version folders in `~/Library/Developer/Xcode/<platform> DeviceSupport`. Xcode copies them again when a device connects | `rm -rf -- <folders>` |
| Swift Package Manager cache | `~/Library/Caches/org.swift.swiftpm` | `rm -rf -- <folder>` |
| CocoaPods cache | `~/Library/Caches/CocoaPods` | `rm -rf -- <folder>` |
| DerivedData by project (folded) | One line per DerivedData folder whose project exists, the largest first, with the workspace or project path | `rm -rf -- <folder>` |
| Simulator runtimes (folded) | One line per runtime that `xcrun simctl runtime list -j` marks as deletable, newest first, with its build, size and last use | `xcrun simctl runtime delete <identifier>` |

A line is shown only when its folder exists. The DerivedData folder is the one Xcode uses (`IDECustomDerivedDataLocation`, else `~/Library/Developer/Xcode/DerivedData`). Before `rm`, DevHub checks that every path is inside the DerivedData folder, `~/Library/Developer/Xcode` or `~/Library/Caches`, and refuses anything else.

### About

Shows the app version (`CFBundleShortVersionString`) and the number of registered features.

## Config

The Settings tab reads no `.devhub` field for its own controls. It shows where the config lives:

1. The three config layers: [extensions §1](../extensions.md#1-where-files-live).
2. `xcode.scheme` and `xcode.bundleID` override the fields of the Projects section: [extensions §2](../extensions.md#2-projectjson).
3. `git.ticketURL` overrides the Ticket link for one project: [extensions §2](../extensions.md#2-projectjson).
4. The `launch identity` tag reads `launch.identity`: [Device identity](device-identity.md).

## Saved preferences

All keys live in the standard `UserDefaults` of the app.

| Key | Value |
|---|---|
| `app.settings` | One JSON object (`AppSettings`): `showDockIcon` (false), `showUsageStrip` (true), `showUsageInMenuBar` (true), `usageProviders` (`all`, or `claude` or `copilot`), `showReviewCountInMenuBar` (true), `globalShortcut` (`optionCommandD`), `editor` (`Xcode`), `terminal` (`Terminal`), `ticketURLTemplate` (empty), `autoFetchMinutes` (0), `notifyWhenPanelClosed` (true), `remembersReviews` (true), `aiTextProvider` (`claude`), `scriptsFolder` (`~/.devhub/scripts`, not shown in Settings) |
| `app.projects` | The project list: id, name, path, scheme, bundle ID |
| `app.selectedProject` | The id of the selected project |

The login item state lives in macOS (`SMAppService`), not in these keys. A missing field in `app.settings` gets its default value.

## Limits

1. With no project, the Settings tab shows "No project yet" until a project is added. Adding a project works from that screen and from the header menu.
2. The notification permission prompt and the menu bar icon state were checked by tests only.
3. The Doctor looks only in the folders listed above. A tool in another folder of your shell `PATH` shows as missing.
4. Re-detect reads only the top level of the project folder. A workspace or project in a subfolder is not found; set `xcode.container` instead.
5. The Editor and Terminal pickers offer a fixed list of apps.
6. Disk: "Delete" of a simulator runtime and of unavailable simulators was checked by tests only, not on this Mac. The sizes come from `du`, so a folder that another process changes can differ a little.
