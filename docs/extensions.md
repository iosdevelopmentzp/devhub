# DevHub extensions: the `.devhub/` folder

This file is the normative schema. The decoder in `DevHub/Core/Config/` must match it. Every field here is documented with its type, default and effect. When a field changes in code, change it here in the same commit.

## 1. Where files live

| Location | Scope | Notes |
|---|---|---|
| `<repo>/.devhub/` | project layer | shared with the team when committed |
| `~/.devhub/projects/<project folder name>/` | user layer for one project | additions without touching the repo |
| `~/.devhub/` | global layer | actions and scripts for every project |

Each layer may contain:

```
project.json        (project and user layers only)
actions/*.json      one action per file, or an array of actions in one file
scripts/*           executable files with a header (section 4)
tabs/*.json         custom tabs
```

Items merge by `id`. The user layer wins over the project layer; the project layer wins over the global layer. `project.json` files merge field by field (objects merge, other values are replaced; the user layer wins). Unknown keys are ignored. A wrong type is an error with the key path, for example `run: run needs one of script, command, terminal or open.` DevHub watches the three folders and their `actions`, `scripts` and `tabs` subfolders and reloads on change; a folder that appears later is picked up within a few seconds. A file that fails to decode shows an inline error with the file name and the reason; the other files load.

## 2. `project.json`

All fields optional. Missing values are detected (see "default").

| Field | Type | Default | Effect |
|---|---|---|---|
| `name` | string | folder name | shown in the header and the project menu |
| `kind` | `"xcode"` \| `"command"` | `xcode` when a workspace or project exists, else `command` | how Build & Run works |
| `xcode.container` | path | first `.xcworkspace`, else first `.xcodeproj` | passed to `xcodebuild -workspace` / `-project` |
| `xcode.scheme` | string | first shared scheme | default scheme in the run bar |
| `xcode.configuration` | string | `Debug` | default configuration |
| `xcode.bundleID` | string | shortest `PRODUCT_BUNDLE_IDENTIFIER` in the pbxproj without `Tests`, `Extension`, `Widget`, `Clip`, `$` | used for log streams, uninstall and clean install when no build ran yet |
| `xcode.schemes` | [string] | every scheme found | the schemes shown in the run bar, in this order; use it to hide test and tool schemes |
| `xcode.bundleIDs` | {key: string} | — | bundle ID per scheme for white-label projects with one scheme per brand; a key is `<scheme>` or `<scheme>/<configuration>` and the more exact key wins; falls back to `xcode.bundleID` |
| `build.command` | path | — | `kind: command` only. Runs before `run.command`. Streams output. |
| `run.command` | path | — | `kind: command` only. May print `@devhub {"app": "<path>"}`; then DevHub installs and launches that app on the target simulator. Otherwise the script launches by itself. |
| `git.baseBranch` | string | `refs/remotes/origin/HEAD`, else `origin/main` | base for merged, rebase, distance, new worktrees |
| `git.commitPrefix.pattern` | regex | `^([A-Z]+-\d+)` | applied to the branch name |
| `git.commitPrefix.format` | string | `$1: ` | the commit box starts with this text when the pattern matches |
| `git.worktrees.folder` | path relative to the repo | sibling `<repo>-<branch>` | where new worktrees go; slashes in branch names become dashes |
| `git.worktrees.include` | [path] | `[]` | files copied from the main checkout into a new worktree when they are missing there |
| `git.worktrees.bootstrap` | path | — | script run inside a new worktree when `bootstrapMarker` exists in the main checkout and not in the worktree |
| `git.worktrees.bootstrapMarker` | path | — | see above; without a marker the bootstrap runs once after creation |
| `launch.profiles[]` | [profile] | `[]` | section 5 |
| `logs.process` | string | `CFBundleExecutable` of the installed app | default process filter of a log stream |
| `logs.subsystem` | string | — | when set, the stream predicate filters by subsystem instead of process |
| `simulators.statusScript` | path | — | section 6 |
| `home.quickActions` | [action id] | built-ins in the default order | order and visibility of the Home grid: when set, only the listed ids appear, in this order (an id that does not exist is skipped); ids may be `builtin.*`, action ids and `script:<name>`; built-ins: `buildRun`, `runAttach`, `openEditor`, `openFolder`, `terminal`, `copyBranch`, `repository`, `newPullRequest` |

## 3. Actions

```json
{
  "id": "clean-derived-data",
  "title": "Clean DerivedData",
  "subtitle": "Removes the DerivedData folder of this project",
  "icon": "trash",
  "tint": "red",
  "placements": ["home.quickActions", "git.pills"],
  "run": { "script": "scripts/clean-derived-data.sh" },
  "cwd": "checkout",
  "inputs": [],
  "confirm": "Delete DerivedData for this project?",
  "refresh": ["worktrees"],
  "when": { "tool": "xcodebuild" }
}
```

| Field | Type | Default | Effect |
|---|---|---|---|
| `id` | string, unique | required | merge key; referenced by tabs and `home.quickActions` |
| `title` | string | required | button or tile title |
| `subtitle` | string | — | second line |
| `icon` | SF Symbol name | `terminal` | |
| `tint` | `gray` `red` `orange` `yellow` `green` `teal` `blue` `indigo` `purple` `pink` | `gray` | icon tile colour |
| `placements` | [placement] | `["home.scripts"]` | where the action appears; `palette` is always added |
| `run` | one of `script`, `command`, `terminal`, `open` | required | section 3.1 |
| `cwd` | `checkout` \| `main` \| `project` \| path | `checkout` | working folder; a relative path starts at the project folder; `checkout` is the checkout chosen in the Git tab (the project folder when none is chosen); `main` is the project folder |
| `inputs` | [input] | `[]` | section 3.2 |
| `confirm` | string | — | inline confirmation text; the action runs after the user confirms |
| `refresh` | [`git` `worktrees` `simulators` `scripts` `logs`] | `[]` | stores refreshed after success; `logs` does nothing yet |
| `when` | object | — | visibility: `{"git": "clean"\|"dirty"}`, `{"simulator": "booted"}` (hidden until the Simulators tab is live), `{"tool": "<executable>"}`, `{"kind": "xcode"\|"command"}` |

### 3.1 `run`

| Shape | Effect |
|---|---|
| `{ "script": "scripts/x.sh" }` | path relative to the `.devhub` folder of the layer that holds the action file (not to the `actions` folder); executed with the context variables; stdout and stderr stream to the Output panel; `@devhub` lines are directives |
| `{ "command": ["git", "fetch", "--prune"] }` | an argument array, placeholders expanded in each argument |
| `{ "terminal": "make lint" }` | opens the configured terminal in `cwd` and runs the text; placeholders are expanded, the `DEVHUB_*` variables are not exported |
| `{ "open": "https://ci.example.com/{branch}" }` | URL or path, placeholders expanded (percent-encoded inside a URL, slashes kept), opened with the default app |

### 3.2 Inputs

```json
{ "key": "target", "title": "Target", "type": "choice", "options": [{"value": "app", "title": "App"}, {"value": "widget", "title": "Widget"}], "default": "app", "remember": true, "placeholder": "…" }
```

| `type` | Control | Value |
|---|---|---|
| `text` | text field | the text |
| `number` | number field | the number as text |
| `toggle` | checkbox | `true` / `false` |
| `choice` | searchable picker over `options` | the option value |
| `branch` | searchable picker over the live branches of the Git tab (local first, then remote branches that have no local copy) | branch name; `default: "current"` means the branch of the checkout chosen in the Git tab |
| `worktree` | searchable picker over the live worktrees (missing ones are left out) | path |
| `simulator` | text field until M4, then a searchable picker (booted first) | UDID; `default: "target"` means the target simulator |
| `scheme` | searchable picker over the schemes of the project | scheme name |
| `file` / `folder` | file or folder picker | path |

`remember: true` stores the last value per project and action. `title` defaults to `key`; `default` may be a string, a number or true or false; `placeholder` is the hint text of an empty field. The `branch`, `worktree`, `choice` and `scheme` pickers fall back to a text field while their list is empty. Until the Simulators tab is live, the `simulator` input is a text field, and `default: "target"` starts empty. Values reach a script as `DEVHUB_INPUT_<KEY uppercased>` and all `run` strings as `{key}`.

### 3.3 Placements

| Placement | Rendered as | Extra context |
|---|---|---|
| `home.quickActions` | tile in the grid | — |
| `home.scripts` | row in the Scripts list with inputs | — |
| `git.pills` | button in the Git header action bar | — |
| `git.branchRow` | item in a branch row's overflow menu | `DEVHUB_BRANCH` of the row |
| `worktrees.row` | item in a worktree row's overflow menu | `DEVHUB_WORKTREE_PATH`, `DEVHUB_BRANCH` of the row |
| `simulators.runBar` | button next to Build & Run | target simulator |
| `simulators.row` | item in a simulator row's overflow menu | `DEVHUB_SIMULATOR_UDID`, `DEVHUB_SIMULATOR_NAME` of the row |
| `logs.toolbar` | button in the Logs toolbar | the chip's simulator |
| `palette` | command palette entry | — |
| `tab.<id>` | row in a custom tab section | — |

### 3.4 Context variables

Every script, command, terminal text and `open` string gets these as environment variables and `{placeholders}`:

`DEVHUB_PROJECT_PATH`, `DEVHUB_PROJECT_NAME`, `DEVHUB_CHECKOUT_PATH`, `DEVHUB_MAIN_PATH`, `DEVHUB_BRANCH`, `DEVHUB_BASE_BRANCH`, `DEVHUB_SCHEME`, `DEVHUB_CONFIGURATION`, `DEVHUB_BUNDLE_ID`, `DEVHUB_SIMULATOR_UDID`, `DEVHUB_SIMULATOR_NAME`, `DEVHUB_APP_PATH`, `DEVHUB_WORKTREE_PATH`, `DEVHUB_INPUT_<KEY>`, `DEVHUB_CONFIG_DIR` (the `.devhub` folder of the layer that holds the action), `DEVHUB_ROW_ID` (row actions of a `view` and row placements), `DEVHUB_VERSION`. A value that is not known yet (simulator, app path before a build) is an empty string, never unset.

Placeholders use the lowercase name without the prefix: `{project_path}`, `{branch}`, `{simulator_udid}`, `{input_key}` is written as `{key}`.

## 4. Scripts with a header

Any executable under `scripts/` is an action without a JSON file. Header lines, in the first 20 lines:

```sh
#!/bin/zsh
# devhub: title = Regenerate resources
# devhub: subtitle = Runs the generator after asset changes
# devhub: icon = wand.and.stars
# devhub: tint = purple
# devhub: input = target, Target, choice, App|Widget
# devhub: input = clean, Clean first, toggle, false
# devhub: placements = home.scripts, git.pills
# devhub: confirm = This takes a minute. Continue?
# devhub: cwd = main
# devhub: refresh = git
```

`input` is `key, title, type, default-or-options`. For `choice` the fourth part lists the options separated by `|`. The file name without extension is the fallback title, and the `id` is `script:<file name without extension>` (`open-jira.sh` is `script:open-jira`). A JSON action with the same `id` in the same layer overrides the header. A file that is not executable shows a row with the hint "Run chmod +x" when it has a `# devhub:` line or starts with `#!`; other files are ignored. A bad header line (unknown key, unknown tint, bad `input`) is shown as a config problem and the rest of the header still applies.

## 5. Launch profiles

```json
{
  "id": "staging",
  "title": "Staging",
  "env": { "API_ENV": "staging" },
  "args": ["-ui-testing"],
  "defaults": [ { "suite": "group.com.example.myapp", "key": "environment", "value": "staging", "type": "string" } ],
  "cleanInstall": false
}
```

| Field | Effect |
|---|---|
| `env` | passed to the app process through `SIMCTL_CHILD_<NAME>` on `simctl launch` |
| `args` | appended after the bundle ID on `simctl launch` |
| `defaults[]` | written into the app's data container before launch: `Library/Preferences/<suite>.plist`; `value` may be a string, a number or true or false; `type` is `string` (default), `bool`, `int` |
| `cleanInstall` | when true the profile always deletes the app and resets the simulator keychain before install |

The selected profile is saved per simulator. Launches from Xcode or the home screen do not get these values; the run bar says so.

## 6. Simulator status script

`simulators.statusScript` runs with `DEVHUB_SIMULATOR_UDID` and `DEVHUB_BUNDLE_ID` for booted, favourite and target simulators, and again after each launch. Its last `@devhub {"view": {"keyValues": [["Environment", "staging"], ["User", "qa-12"]]}}` line, or its last plain line, is shown under the device name. The result is cached until the next launch or refresh. The script must finish in under 5 seconds; a slower script is cancelled and the row shows "status timed out".

## 7. Script line protocol

A line that starts with `@devhub ` followed by one JSON object is a directive. Other lines are plain output.

| Directive | Effect |
|---|---|
| `{"progress": "Compiling", "fraction": 0.4}` | footer and run bar step text; `fraction` optional (0 to 1) |
| `{"toast": "Done"}` | toast |
| `{"copy": "text"}` | clipboard plus toast |
| `{"open": "https://… or /path"}` | opens with the default app |
| `{"notify": "Title", "body": "…"}` | system notification when the panel is closed |
| `{"refresh": ["git", "simulators"]}` | refreshes stores |
| `{"error": "message"}` | the run is marked failed with this message even with exit code 0 |
| `{"app": "/path/App.app"}` | `run.command` only: the app to install and launch |
| `{"view": {...}}` | replaces the result area of the action (custom tab section or Output entry) |

`view` shapes:

```json
{ "rows": [ { "id": "r1", "title": "Device A", "subtitle": "iOS 26", "tags": [ { "text": "ok", "tint": "green" } ],
             "actions": [ { "title": "Open", "run": { "open": "https://…" } }, { "title": "Reset", "run": { "script": "scripts/reset.sh" }, "confirm": "Reset?" } ] } ] }
{ "keyValues": [ ["Version", "1.2"], ["Build", "345"] ] }
{ "text": "free text, monospaced" }
```

Row actions use the same `run` shapes as actions and get the row's `id` as `DEVHUB_ROW_ID`.

## 8. Custom tabs

```json
{
  "id": "qa",
  "title": "QA",
  "icon": "wrench.and.screwdriver",
  "searchPrompt": "Search QA tools",
  "sections": [
    { "title": "Accounts", "actions": ["login-as-tester", "reset-account"] },
    { "title": "Devices", "source": { "script": "scripts/list-devices.sh", "refresh": "onOpen" } }
  ]
}
```

| Field | Effect |
|---|---|
| `id` | tab id; `tab.<id>` placement; ⌘ number after the built-in tabs |
| `title`, `icon`, `searchPrompt` | tab bar and header search |
| `sections[].actions` | action ids rendered as rows with their inputs and a Run button |
| `sections[].source.script` | a script whose `view` directive renders the section; `refresh` is `onOpen` (default), `manual` (a refresh button) or a number of seconds |

The header search filters rows by title, subtitle and tags.
