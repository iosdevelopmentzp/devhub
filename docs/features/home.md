# Home

Home is the first tab (⌘1). It shows the selected project, the quick actions, the scripts from the `.devhub` folders and the last events of the app.

Code: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Home/`, `Features/Scripts/`, `Features/ConfigActions/`.

## What it shows

The tab has six parts, from top to bottom.

1. **Project card.**
   - The project name and the project path. A click on the path copies it.
   - A blue tag with the branch of the main checkout. A click copies the branch name.
   - Status tags of the main checkout: `clean` or `N changed`, `↑N` (commits to push), `↓N` (commits to pull).
   - Four buttons: Finder, Xcode, Terminal and the code host (for example "GitHub").
2. **Keep Mac awake.** A switch. While it is on, DevHub holds a `PreventUserIdleSystemSleep` power assertion, so the Mac does not go to sleep when idle. The display can still turn off. Turning the switch off or quitting DevHub releases the assertion. The menu bar icon shows a cup while the switch is on.
3. **Config problems.** This part appears only when a `.devhub` file has an error. Each row shows the file and the reason. A Reload button reads the config again.
4. **Quick actions.** A grid of tiles, four per line. A tile is a built-in action or a config action. A running action shows a small spinner on its tile. The result of a config action (output view, failure) appears under the grid.
5. **Scripts.** One row per action with the `home.scripts` placement. A row shows the icon, title, subtitle, file name, "ran 5 min ago" or "never run", the number of inputs and the config layer (`project`, `user` or `global`). The header shows the scripts folder of the first layer that exists.
6. **Recent.** The last 8 events of the app (commands, failures, info), newest first, with a coloured dot: green for success, red for failure, grey for info.

The header search filters the tiles by title and subtitle, and the script rows by title, subtitle and file name.

When no project is added yet, the panel shows "No project yet" and an Add Project button instead of Home.

## Actions

### Project card

| Button | What it does | Command |
|---|---|---|
| Copy path (icon) | Copies the project path | — |
| Finder | Opens the main checkout in Finder | `NSWorkspace.open` on the folder |
| Xcode | Opens `xcode.container` of the main checkout, else its first `.xcworkspace`, else its first `.xcodeproj` | `open -a Xcode <container>` |
| Terminal | Opens the terminal app from Settings in the project folder | `open -a <terminal> <path>` (Ghostty: `open -na Ghostty --args --working-directory=<path>`) |
| Code host button | Opens the web page of the repository | reads `git remote get-url <remote>` and opens the web URL |

### Built-in quick actions

| Tile | What it does | Command |
|---|---|---|
| Build & Run | Shows the Simulators tab and starts Build & Run with the run bar options | see the Simulators tab |
| Run & Attach | Shows the Simulators tab, builds, launches and attaches Xcode | see the Simulators tab |
| Open in Xcode | Same as the Xcode button, for the main checkout | `open -a Xcode <container>` |
| Open folder | Opens the main checkout in Finder | `NSWorkspace.open` |
| Terminal here | Opens the terminal app in the main checkout | `open -a <terminal> <path>` |
| Copy branch | Copies the branch of the main checkout. Disabled when there is no branch | — |
| Repository | Opens the web page of the repository | `git remote get-url <remote>` |
| New Pull Request | Opens the web page that creates a request from the branch of the main checkout into the base branch. It does not open the form inside DevHub | GitHub: `<web>/compare/<base>...<branch>?expand=1`; GitLab: `<web>/-/merge_requests/new?merge_request[source_branch]=<branch>&merge_request[target_branch]=<base>` |
| Pull Requests | Shows the Pull Requests tab. Only when it is listed in `home.quickActions` | — |

Build & Run and Run & Attach are disabled while a build runs.

### Config actions (tiles and script rows)

A config action runs in the same way on every placement:

1. When the action has `inputs` or `confirm`, a prompt opens under the tile grid or under the script row. Run starts the action, Cancel closes the prompt.
2. `run.script` starts the file with the context variables. A file without the executable bit runs through `/bin/zsh`. Output lines go to the Output panel. `@devhub` lines are directives.
3. `run.command` starts the argument array after placeholder expansion.
4. `run.terminal` opens the terminal app from Settings and runs the text there.
5. `run.open` opens a URL or a path with the default app.
6. On success, DevHub refreshes the stores named in `refresh`. On failure, a toast and a red "Recent" row show the message.

A script row also has:

| Control | What it does |
|---|---|
| Run | Starts the action (or opens its prompt) |
| Stop (while running) | Cancels the run |
| Overflow menu: Edit in `<editor>` | Opens the script file in the editor from Settings (`open -a <editor> <file>`) |
| Overflow menu: Reveal in Finder | Shows the script file in Finder |
| "Run chmod +x" tag | Shown for a file without the executable bit. A click copies `chmod +x "<file>"`. Run stays disabled |
| Overflow menu: Copy chmod Command | Shown for a file without the executable bit. Copies the same `chmod +x "<file>"` command |

The lightbulb button shows a short guide with a header example. The arrow button opens the first `.devhub` folder that exists in Finder.

### Other controls

| Control | What it does |
|---|---|
| Reload (config problems) | Reads every `.devhub` layer again |
| Clear (Recent) | Removes all Recent rows |
| Click on a Recent title or detail | Copies the text |

## Config

| Field | Effect on Home | Reference |
|---|---|---|
| `home.quickActions` | Order and visibility of the tiles. Without it, Home shows the built-ins (without `builtin.pullRequests`), then every action with the `home.quickActions` placement | [`project.json`](../extensions.md#2-projectjson) |
| Actions with `placements: ["home.quickActions"]` | Tiles | [Placements](../extensions.md#33-placements) |
| Actions with `placements: ["home.scripts"]` (the default) | Script rows | [Actions](../extensions.md#3-actions) |
| Header scripts in `scripts/` | Script rows with the id `script:<file name>` | [Scripts with a header](../extensions.md#4-scripts-with-a-header) |
| `inputs`, `confirm`, `cwd`, `refresh`, `when` | Prompt, working folder, refresh after success, visibility | [Actions](../extensions.md#3-actions), [Inputs](../extensions.md#32-inputs) |
| `xcode.scheme` | The subtitle of the Build & Run tile ("Scheme X") | [`project.json`](../extensions.md#2-projectjson) |
| `git.remote`, `git.baseBranch` | The repository link and the target of the New Pull Request link | [`project.json`](../extensions.md#2-projectjson) |

The three config layers and their merge rules are in [Where files live](../extensions.md#1-where-files-live). DevHub reads the config again each time the panel opens and when a watched file changes.

## Saved preferences

| Key | What it keeps |
|---|---|
| `configActions.lastRun` | The time of the last run, per project and action ("ran 5 min ago") |
| `configActions.inputs` | The last input values of inputs with `remember: true`, per project and action |
| `app.settings` | Settings values that Home uses: `editor`, `terminal` |

The Recent list is not saved. It is empty after a restart.

## Limits

- Recent keeps only the last 8 events, in memory.
- The New Pull Request tile opens the web page. The form inside DevHub is in the Git and Pull Requests tabs.
- A tile shows no prompt of its own. The prompt and the result of a config tile appear under the whole grid.
- `refresh: ["logs"]` does nothing yet.
- With no project, Home is not shown. The Settings tab also shows "No project yet" until a project is added (`docs/STATUS.md`, known gaps).
