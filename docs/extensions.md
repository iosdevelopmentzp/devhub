# DevHub extensions: the `.devhub/` folder

This file is the normative schema. The decoder (`Packages/DevHubKit/Sources/DevHubDomain/Models/Config/`, `Policies/ConfigDecoding.swift`, `Policies/ScriptHeaderParser.swift`) must match it. Every field here is documented with its type, default and effect. When a field changes in code, change it here in the same commit.

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
| `xcode.bundleID` | string | shortest `PRODUCT_BUNDLE_IDENTIFIER` in the pbxproj without `Tests`, `Extension`, `Widget`, `Intents`, `Clip`, `Notification`, `$` | used for log streams, deep links, push, uninstall and clean install when no build ran yet |
| `xcode.schemes` | [string] | every scheme found | the schemes shown in the run bar, in this order; use it to hide test and tool schemes |
| `xcode.bundleIDs` | {key: string} | — | bundle ID per scheme for white-label projects with one scheme per brand; a key is `<scheme>` or `<scheme>/<configuration>` and the more exact key wins; falls back to `xcode.bundleID` |
| `xcode.developerDir` | string | — | the Xcode of this project: an `.app` path (`/Applications/Xcode-beta.app`) or its `Contents/Developer` folder; DevHub passes it as `DEVELOPER_DIR` to `xcodebuild`, `xcrun` (simctl) and `xed`, and opens that Xcode. A choice in Settings → Projects wins; without both the Xcode of `xcode-select` is used |
| `build.command` | path | — | `kind: command` only. Runs before `run.command` in the checkout of the run bar, with the variables of section 3.4. Streams output. A file without the executable bit runs through `/bin/zsh`. |
| `run.command` | path | — | `kind: command` only. Either command may print `@devhub {"app": "<path>"}` (a relative path is read from the checkout); then DevHub installs and launches that app on the target simulator with the launch profile. Otherwise the script launches by itself. |
| `git.remote` | string | `origin` | the remote that fetch, pull, push, the remote branch list, the web link and the base branch use |
| `git.host.kind` | `"github"` \| `"gitlab"` | `github` when the host of the remote contains `github`, else `gitlab` | which CLI (`gh` or `glab`) and which words the merge request features use; set it for GitHub Enterprise on a custom host |
| `git.host.name` | string | the host of the remote URL | passed to `gh --hostname` / `glab --hostname` |
| `ci.kind` | `"circleci"` \| `"none"` | `circleci` when `.circleci/config.yml` exists in the main checkout, else none | which CI tool reads the jobs of a pull request; `"none"` turns the detection off |
| `ci.project` | string | resolved by the `circleci` tool from the remote | the CircleCI project slug (`gh/<owner>/<repo>` or `circleci/<org id>/<project id>`), passed as `--project` to `run list` and `run approve`, and used for the flaky test list |
| `git.baseBranch` | string | `<remote>/HEAD`, else `<remote>/main` | base for merged, rebase, distance, new worktrees |
| `git.protectedBranches` | [string] | `["main", "master", "develop", "dev"]` | never offered by "Clean Up" in the merged branches section; the base branch is always protected |
| `git.commitPrefix.pattern` | regex | `^([A-Z][A-Z0-9]+-\d+)` | applied to the branch name; the same pattern without `^` finds the ticket key for the ticket chip and a new merge request title; group 1 is the key; a pattern that does not compile finds nothing |
| `git.commitPrefix.format` | string | `$1: ` | the commit box starts with this text when the pattern matches |
| `git.ticketURL` | string | the "Ticket link" of Settings | `{key}` is replaced with the ticket key; the ticket chip opens it; without a link the chip copies the key |
| `git.worktrees.folder` | path relative to the repo | `.worktrees` when git ignores `.worktrees/` (Worktrees → New… → "Keep Inside the Project"), else sibling `<repo>-<branch>` | where new worktrees go; slashes in branch names become dashes |
| `git.worktrees.include` | [path] | `[]` | files copied from the main checkout into a new worktree when they are missing there |
| `git.worktrees.bootstrap` | path relative to the worktree | — | script run inside a new worktree when `bootstrapMarker` exists in the main checkout and not in the worktree; an executable file runs as is, another file runs with `zsh`; a worktree row offers it in its menu |
| `git.worktrees.bootstrapMarker` | path | — | see above; without a marker the bootstrap runs once after creation |
| `git.pullRequests.targets` | [string] | `dev`, the base branch, `develop`, `main`, `master` | the order of the target picker in the new request form; names that do not exist on the remote are skipped; the other remote branches follow, sorted |
| `git.pullRequests.template` | path relative to the checkout | `.github/pull_request_template.md` on GitHub, `.gitlab/merge_request_templates/Default.md` on GitLab | the description of a new request starts with this file when it exists |
| `git.pullRequests.staleDays` | number | `14` | an open request without an update for this many days gets the `stale` tag |
| `git.pullRequests.hiddenFiles` | [pattern] | `[]` (nothing hidden) | files of a request that match one pattern are hidden from the file list in the details until "Show N hidden"; a pattern is a shell glob (`*` also matches `/`) tried against the full path and against the file name. Without it, the details only suggest hiding tests, Xcode project files and lock files, and the files you hide with the eye-slash button stay hidden per project |
| `git.pullRequests.fileGroups` | [group] | `[]` | named groups of files in the details of a request: `{ "name": "Tests", "patterns": ["*Tests/*", "*Tests.swift"], "hidden": true }`. Each file of a request lands in the first group whose pattern matches its full path or its file name (shell globs, `*` also matches `/`). A matched group shows as a chip above the file list with its count; a click hides or shows the group for that request. `hidden: true` starts hidden. A group needs a name and at least one pattern; a second group with the same name is dropped |
| `git.pullRequests.defaults.draft` | bool | `false` | the Draft box of the new request form |
| `git.pullRequests.defaults.deleteSourceBranch` | bool | `true` | the "Delete source branch" box of the new request form |
| `git.pullRequests.defaults.squash` | bool | `false` | the Squash box of the new request form |
| `ai.commands` | object | `{ "claude": "claude \"$(cat {prompt})\"", "copilot": "copilot -i \"$(cat {prompt})\"" }` | one command per AI tool (`claude`, `copilot`). "Fix with AI" (review threads, failed tests, build errors) runs the command of the chosen tool in a terminal inside the checkout; `{prompt}` becomes the quoted path of the prompt file |
| `ai.reviewCommand` | string | — | the old name of `ai.commands.claude`; read when `ai.commands.claude` is missing |
| `ai.textCommands` | object | `{ "claude": "claude -p \"$(cat {prompt})\" --output-format text", "copilot": "copilot -p \"$(cat {prompt})\" -s --no-ask-user --no-color --stream off" }` | one command per AI tool (`claude`, `copilot`) for "Write with AI" (commit message, new request) and "Explain" (request details). DevHub runs it once with `/bin/sh -c` in the main checkout, without a terminal, and reads its standard output as the answer; `{prompt}` becomes the quoted path of the prompt file. The command must print only the answer and must not wait for input. An empty value keeps the default |
| `launch.profiles[]` | [profile] | `[]` | section 5 |
| `launch.identity.variable` | string | — | the environment variable that carries the identity of a launch (a device or account ID). The identity panel of a simulator chooses the value. Without `launch.identity` the panel is hidden |
| `launch.identity.keptVariable` | string | — | a second variable that gets the same value, for an app that keeps the identity across launches; it is empty when no identity is chosen. When the app binary contains this name, the identity panel shows "ID kept" |
| `launch.identity.args` | [string] | `[]` | arguments added to every launch of a project with `launch.identity` |
| `launch.identity.idPrefix` | string | `devhub-` | the start of a new identity; DevHub adds 8 hex characters |
| `launch.identity.cleanInstallOnChange` | bool | `true` | when the app on the simulator has another identity than the chosen one, a launch from DevHub deletes the app, resets the simulator keychain and installs it again. With no chosen identity, this happens only when the app still carries an identity that DevHub set; the app's own identity stays |
| `launch.identity.hookMarker` | string | the value of `variable` | the text DevHub looks for in the app binary; when it is found, the identity panel shows a green tag with the variable name, else a red "no … hook" tag |
| `network.baseURLVariable` | string | — | the environment variable that gets the URL of the DevHub mock server when the app is relaunched through it. Without it the mock server cannot redirect the app |
| `network.mocksFolder` | path | `~/.devhub/mocks/<project folder name>` | where the mock sets of the project are saved. A relative path starts at the project folder, `~` is the home folder. A change reloads the sets |
| `tracker.kind` | `"jira"` \| `"none"` | `jira` when `git.ticketURL` contains `atlassian` or `jira`, else `none` | the issue tracker of Utils → Tickets. DevHub reads Jira through the `jira` tool (`brew install jira-cli`, set up with `jira init`); `none` hides the list |
| `tracker.project` | string | the default project of the `jira` config | the Jira project key, passed as `-p` to every list |
| `tracker.statuses` | [string] | `["To Do", "In Progress", "In Review", "Done"]` | the statuses of the "Move to" menu of a ticket row, in this order; the current status is left out |
| `tracker.startStatus` | string | `In Progress` | the status of the Start button of a ticket row (`jira issue move <key> <status>`) |
| `tracker.filter` | JQL | — | added to every list with `AND (…)`, for example `type != Epic` |
| `tracker.branchFormat` | string | `feature/{key}-{slug}` | the branch name that "Copy Branch Name" gives: `{key}` is the ticket key, `{slug}` the summary in lower case ASCII with dashes, at most 40 characters |
| `logs.process` | string | `CFBundleExecutable` of the installed app, else the scheme | default process filter of a new log stream; each stream can change it in the Logs toolbar |
| `logs.subsystem` | string | — | default subsystem of a new log stream; when set, the stream predicate filters by subsystem instead of process |
| `simulators.statusScript` | path | — | section 6 |
| `home.quickActions` | [action id] | built-ins in the default order | order and visibility of the Home grid: when set, only the listed ids appear, in this order (an id that does not exist is skipped); ids may be `builtin.*`, action ids and `script:<name>`; built-ins: `buildRun`, `runAttach`, `openEditor`, `openFolder`, `terminal`, `copyBranch`, `repository`, `newPullRequest`. Built-ins: `builtin.buildRun`, `builtin.runAttach`, `builtin.openEditor`, `builtin.openFolder`, `builtin.terminal`, `builtin.copyBranch`, `builtin.repository`, `builtin.newPullRequest`, `builtin.build` (build only, no launch; only when listed) and `builtin.pullRequests` (opens the pull request tab; only when listed) |

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
| `run` | one of `script`, `command`, `terminal`, `open`, `copy` | required | section 3.1 |
| `cwd` | `checkout` \| `main` \| `project` \| path | `checkout` | working folder; a relative path starts at the project folder; `checkout` is the checkout chosen in the Git tab (the project folder when none is chosen); `main` is the project folder |
| `inputs` | [input] | `[]` | section 3.2 |
| `confirm` | string | — | inline confirmation text; the action runs after the user confirms. A `confirm` on the chosen option of a `choice` input (section 3.2) wins over this text |
| `refresh` | [`git` `worktrees` `simulators` `scripts` `logs` `pullRequests` `network` `appData`] | `[]` | stores refreshed after success; `pullRequests` reads the pull request tab, the open requests and the Git status line again; `network` reads the mock sets again; `appData` reads an open App Data panel again; `logs` does nothing yet |
| `when` | object | — | visibility: `{"git": "clean"\|"dirty"}`, `{"simulator": "booted"}` (the target simulator is booted), `{"tool": "<executable>"}`, `{"kind": "xcode"\|"command"}`, `{"host": "github"\|"gitlab"}` (the code host of the remote) |

### 3.1 `run`

| Shape | Effect |
|---|---|
| `{ "script": "scripts/x.sh" }` | path relative to the `.devhub` folder of the layer that holds the action file (not to the `actions` folder); executed with the context variables; stdout and stderr stream to the Output panel; `@devhub` lines are directives |
| `{ "command": ["git", "fetch", "--prune"] }` | an argument array, placeholders expanded in each argument |
| `{ "terminal": "make lint" }` | opens the configured terminal in `cwd` and runs the text; placeholders are expanded, the `DEVHUB_*` variables are not exported |
| `{ "open": "https://ci.example.com/{branch}" }` | URL or path, placeholders expanded (percent-encoded inside a URL, slashes kept), opened with the default app |
| `{ "copy": "{env} coins {user} {amount}", "open": "slack://channel?team=T0&id=C0" }` | puts the text on the clipboard with the placeholders expanded, then opens `open` when it is set (same rules as the `open` run). No process runs. The prompt shows the rendered text under the inputs before the user presses Copy. Every copy lands in the Recent list of its custom tab with Resend |

### 3.2 Inputs

```json
{ "key": "target", "title": "Target", "type": "choice", "options": [{"value": "app", "title": "App"}, {"value": "widget", "title": "Widget", "confirm": "Build the widget?"}], "default": "app", "remember": true, "recent": false, "placeholder": "…" }
```

| `type` | Control | Value |
|---|---|---|
| `text` | text field | the text |
| `number` | number field | the number as text |
| `toggle` | checkbox | `true` / `false` |
| `choice` | searchable picker over `options` | the option value |
| `branch` | searchable picker over the live branches of the Git tab (local first, then remote branches that have no local copy) | branch name; `default: "current"` means the branch of the checkout chosen in the Git tab |
| `worktree` | searchable picker over the live worktrees (missing ones are left out) | path |
| `simulator` | searchable picker over the simulators (booted first) | UDID; `default: "target"` means the target simulator |
| `scheme` | searchable picker over the schemes of the project | scheme name |
| `file` / `folder` | file or folder picker | path |

`remember: true` stores the last value per project and action. `recent: true` on a `text` or `number` input keeps the last 12 distinct values per project and action (or per tab for a shared input) and shows them in a clock menu next to the field, with "Forget" for each. An option of a `choice` input may carry `confirm`: when that option is chosen, its text is the confirmation of the action and wins over the action's own `confirm`; an action without inputs then asks too. `title` defaults to `key`; `default` may be a string, a number or true or false; `placeholder` is the hint text of an empty field. The `branch`, `worktree`, `choice` and `scheme` pickers fall back to a text field while their list is empty. Values reach a script as `DEVHUB_INPUT_<KEY uppercased>` and all `run` strings as `{key}`.

### 3.3 Placements

| Placement | Rendered as | Extra context |
|---|---|---|
| `home.quickActions` | tile in the grid | — |
| `home.scripts` | row in the Scripts list with inputs | — |
| `git.pills` | button in the Git header action bar | — |
| `git.branchRow` | item in a branch row's context menu (right-click) | `DEVHUB_BRANCH`, `DEVHUB_WORKTREE_PATH` (when checked out), `DEVHUB_ROW_ID` = the branch name |
| `worktrees.row` | item in a worktree row's context menu (right-click) | `DEVHUB_WORKTREE_PATH`, `DEVHUB_BRANCH` of the row, `DEVHUB_ROW_ID` = the path |
| `simulators.runBar` | button in the run bar, under the target | the target simulator |
| `simulators.row` | item in a simulator row's overflow menu | `DEVHUB_SIMULATOR_UDID`, `DEVHUB_SIMULATOR_NAME` of the row, `DEVHUB_ROW_ID` = the UDID |
| `simulators.appData` | button in the App Data panel of a simulator, under its header | `DEVHUB_SIMULATOR_UDID`, `DEVHUB_SIMULATOR_NAME` of the row, `DEVHUB_BUNDLE_ID` = the app of the panel, `DEVHUB_ROW_ID` = the UDID; the panel reads the data again when the action ends, also after a failure |
| `logs.toolbar` | button in the Logs toolbar | the simulator of the stream, else the target simulator |
| `pullRequests.row` | item in the overflow and context menu of an open pull request row | `DEVHUB_PR_NUMBER`, `DEVHUB_PR_URL`, `DEVHUB_BRANCH` = the source branch, `DEVHUB_ROW_ID` = the number |
| `network.toolbar` | button in the toolbar of the Network tab | `DEVHUB_SIMULATOR_UDID`, `DEVHUB_SIMULATOR_NAME` of the simulator chosen in the toolbar |
| `palette` | command palette entry | — |
| `tab.<id>` | row in a custom tab section | — |

In a row placement, the inputs and the confirmation of an action open under that row. In a bar or a toolbar, they open under the bar, with the result area of the action.

### 3.4 Context variables

Every script, command, terminal text and `open` string gets these as environment variables and `{placeholders}`:

`DEVHUB_PROJECT_PATH`, `DEVHUB_PROJECT_NAME`, `DEVHUB_CHECKOUT_PATH`, `DEVHUB_MAIN_PATH`, `DEVHUB_BRANCH`, `DEVHUB_BASE_BRANCH`, `DEVHUB_SCHEME`, `DEVHUB_CONFIGURATION`, `DEVHUB_BUNDLE_ID`, `DEVHUB_SIMULATOR_UDID`, `DEVHUB_SIMULATOR_NAME`, `DEVHUB_APP_PATH`, `DEVHUB_WORKTREE_PATH`, `DEVHUB_INPUT_<KEY>`, `DEVHUB_CONFIG_DIR` (the `.devhub` folder of the layer that holds the action), `DEVHUB_ROW_ID` (row actions of a `view` and row placements), `DEVHUB_PR_NUMBER` and `DEVHUB_PR_URL` (the `pullRequests.row` placement), `DEVHUB_PROFILE` (the id of the launch profile chosen in the run bar for that simulator), `DEVHUB_HOST` (`github` or `gitlab`, the code host of the remote), `DEVHUB_APP_CONTAINER` and `DEVHUB_DATA_CONTAINER` (the app bundle folder and the data folder of the app on that simulator, from `xcrun simctl get_app_container`; empty when the app is not installed), `DEVHUB_GROUP_CONTAINERS` (the app group containers of the app on that simulator, one line per group: the group ID, a tab, the folder; from `xcrun simctl get_app_container <udid> <bundle ID> groups`, so it is empty on a simulator that is not booted), `DEVHUB_SIMULATOR_STATE` (`booted`, `shutdown`, `booting` or `shutting-down`, the last known state of that simulator; empty when there is no simulator), `DEVHUB_SIMULATOR_KIND` (`simulator`, or `device` for a physical iPhone or iPad from the Devices section; empty when there is no simulator), `DEVHUB_VERSION`. DevHub also finds the app and data containers on a simulator that is shut down: it then reads the folders of the simulator. The status script (`simulators.statusScript`) gets the same variables for its simulator. A value that is not known yet (simulator, app path before a build) is an empty string, never unset.

Placeholders use the lowercase name without the prefix: `{project_path}`, `{branch}`, `{simulator_udid}`, `{input_key}` is written as `{key}`.

A script that changes the data of the app on a simulator:

```sh
while IFS=$'\t' read -r group folder; do
    [ -n "$folder" ] || continue
    rm -rf "$folder/Library/Caches"
done <<< "$DEVHUB_GROUP_CONTAINERS"

[ -n "$DEVHUB_DATA_CONTAINER" ] || { echo '@devhub {"error": "The app is not installed on this simulator"}'; exit 1; }
plist="$DEVHUB_DATA_CONTAINER/Library/Preferences/$DEVHUB_BUNDLE_ID.plist"
if [ "$DEVHUB_SIMULATOR_STATE" = booted ]; then
    xcrun simctl spawn "$DEVHUB_SIMULATOR_UDID" defaults delete "$plist" onboardingDone || true
else
    plutil -remove onboardingDone "$plist" || true
fi
```

Check that a folder is not empty before `rm -rf`: an empty `DEVHUB_GROUP_CONTAINERS` gives one empty line. On a booted simulator, change user defaults only through `xcrun simctl spawn <udid> defaults`: `cfprefsd` inside the simulator keeps the values in memory and writes them back over a changed file. On a simulator that is shut down, change the file.

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
  "cleanInstall": false,
  "tint": "indigo"
}
```

| Field | Effect |
|---|---|
| `env` | passed to the app process through `SIMCTL_CHILD_<NAME>` on `simctl launch` |
| `args` | appended after the bundle ID on `simctl launch` |
| `defaults[]` | written after install and before launch into `Library/Preferences/<suite>.plist` of the app's data container, or of the app group container when `suite` starts with `group.`; `value` may be a string, a number or true or false; `type` is `string` (default), `bool`, `int`, `float` |
| `cleanInstall` | when true the profile always deletes the app and resets the simulator keychain before install |
| `storage` | `{"suite": "group.com.example.myapp", "key": "environment"}`: where the app saves its current profile; DevHub reads it to show which profile the installed app uses (same container rule as `defaults`) |
| `upstream` | the URL of the real server for this profile; the mock server forwards to it in Passthrough mode |
| `production` | when true the profile tag in the identity panel is red and the mock server refuses to run with it |
| `tint` | the colour of the profile tag in the identity summary and panel: `gray`, `red`, `orange`, `yellow`, `green`, `teal`, `blue`, `indigo`, `purple` or `pink`. Default: teal, red for a `production` profile. A set `tint` wins over that red |

The selected profile is saved per simulator. The run bar shows a picker when the project has profiles. Launches from Xcode or the home screen do not get these values; the hint of the profile summary says so. A clean install also removes the defaults that an earlier profile wrote.

## 6. Simulator status script

`simulators.statusScript` runs with `DEVHUB_SIMULATOR_UDID` and `DEVHUB_BUNDLE_ID` for booted, favourite and target simulators, and again after each launch. It also runs for a connected physical device, with `DEVHUB_SIMULATOR_KIND=device`, `DEVHUB_SIMULATOR_STATE=booted` and empty container variables: a script that reads files of the app must copy them first (`xcrun devicectl device copy from --device "$DEVHUB_SIMULATOR_UDID" --domain-type appDataContainer --domain-identifier "$DEVHUB_BUNDLE_ID" --source <file> --destination <local file>`). Its last `@devhub {"view": {"keyValues": [["Environment", "staging"], ["User", "qa-12"]]}}` line, or its last plain line, is shown under the device name, in the simulator row and under the target of the run bar. The result is cached until the next launch or refresh. The script must finish in under 5 seconds; a slower script is cancelled and the row shows "status timed out". A non-zero exit code shows the last line in red.

The script may also print a `state` line (section 7) with what the app reports about itself: identity, profile, host, user and version. DevHub keeps the last one per simulator.

A relative path is looked up in the user, project and global config folders, then in the project folder; the first file that exists runs. When no file exists, the row shows "Status script not found". A file without the executable bit runs through `/bin/zsh`.

## 7. Script line protocol

A line that starts with `@devhub ` followed by one JSON object is a directive. Other lines are plain output.

| Directive | Effect |
|---|---|
| `{"progress": "Compiling", "fraction": 0.4}` | the detail text and the bar of the operation card in the tray at the bottom of the tab, and the footer; `fraction` optional (0 to 1) |
| `{"toast": "Done"}` | toast |
| `{"copy": "text"}` | clipboard plus toast |
| `{"open": "https://… or /path"}` | opens with the default app |
| `{"notify": "Title", "body": "…"}` | system notification, also while the panel is open, when macOS allows notifications for DevHub |
| `{"refresh": ["git", "simulators"]}` | refreshes stores |
| `{"error": "message"}` | the run is marked failed with this message even with exit code 0 |
| `{"app": "/path/App.app"}` | `build.command` and `run.command` only: the app to install and launch |
| `{"state": {"identity": "devhub-3f9a1c2e", "profile": "staging", "host": "api.staging.example.com", "user": "qa-12", "version": "2.4.0", "tags": [{"text": "beta", "tint": "purple", "icon": "flask", "hint": "Beta features are on"}]}}` | `simulators.statusScript` only: what the app reports about itself; every field is optional. The clean install rule compares `identity` with the chosen identity, and the mock server status line uses `host`. `tags` are shown after the identity line of the simulator row and under the target of the run bar; a tag has `text` and optional `tint`, `icon` (an SF Symbol name) and `hint` |
| `{"view": {...}}` | replaces the result area of the action (custom tab section or Output entry) |

`view` shapes:

```json
{ "rows": [ { "id": "r1", "title": "Device A", "subtitle": "iOS 26", "tags": [ { "text": "ok", "tint": "green" } ],
             "actions": [ { "title": "Open", "run": { "open": "https://…" } }, { "title": "Reset", "run": { "script": "scripts/reset.sh" }, "confirm": "Reset?" } ] } ] }
{ "keyValues": [ ["Version", "1.2"], ["Build", "345"] ] }
{ "text": "free text, monospaced" }
```

A tag has `text` and optional `tint`, `icon` (an SF Symbol name) and `hint`. Row actions use the same `run` shapes as actions and get the row's `id` as `DEVHUB_ROW_ID`.

## 8. Custom tabs

```json
{
  "id": "qa",
  "title": "QA",
  "icon": "wrench.and.screwdriver",
  "searchPrompt": "Search QA tools",
  "placement": "bar",
  "inputs": [
    { "key": "env", "title": "Environment", "type": "choice", "options": [{ "value": "qa" }, { "value": "prod", "confirm": "Run against PROD?" }], "default": "qa" },
    { "key": "user", "title": "User ID", "type": "text", "recent": true }
  ],
  "sections": [
    { "title": "Accounts", "actions": ["login-as-tester", "reset-account"] },
    { "title": "Devices", "source": { "script": "scripts/list-devices.sh", "refresh": "onOpen" } }
  ]
}
```

| Field | Effect |
|---|---|
| `id` | tab id; `tab.<id>` placement; the saved tab `tab.<id>` |
| `title`, `icon`, `searchPrompt` | the tab button and the search field of the tab |
| `placement` | `utils` (default): the tab is a sub-tab of the Utils tab. `bar`: the tab sits in the tab bar after the built-in tabs and gets the next free ⌘ number up to ⌘9. A right-click on the tab ("Move to Utils", "Show in Tab Bar") saves the user's own choice under `tabs.layout`, which wins over this field |
| `inputs` | inputs shared by every action and source script of the tab (section 3.2 shapes). They show in a bar under the toolbar, and their values are saved per project and tab. Every run of the tab gets them as `DEVHUB_INPUT_<KEY>` and `{key}`; an input of the action with the same key wins. A `confirm` on the chosen option asks before every action of the tab |
| `sections[].actions` | action ids rendered as rows with their inputs and a Run button |
| `sections[].source.script` | a script whose `view` directive renders the section; `refresh` is `onOpen` (default), `manual` (a refresh button) or a number of seconds |

The search field in the toolbar filters rows by title, subtitle and tags. A tab whose actions have a `copy` run ends with a "Recent" section: the last 30 copied texts of the project for that tab, newest first, each with Resend (copies again and opens the target again) and Remove, plus Clear in the header.

## 9. Mock set files

The Network tab saves each mock set as `<set name>.json` in `network.mocksFolder` (default `~/.devhub/mocks/<project folder name>`). A team can keep the folder in the repository and edit the files by hand. DevHub reloads them when the panel opens.

```json
{
  "version": 1,
  "id": "6B1F7C2A-1111-4C2B-9D3E-000000000001",
  "name": "VIP user",
  "rules": [
    { "id": "…", "enabled": true, "method": "GET", "path": "/v1/profile/**", "query": "lang=en",
      "respond": { "status": 200, "delay": 0.2, "headers": { "Content-Type": "application/json" }, "body": "{\"vip\":true}" } },
    { "id": "…", "enabled": true, "method": "POST", "path": "/graphql", "operationName": "GetProfile",
      "patch": { "delay": 0, "operations": [ { "path": "data.profile.vip", "value": true }, { "path": "data.profile.banner", "remove": true } ] } }
  ]
}
```

| Field | Effect |
|---|---|
| `method` | HTTP method; empty or missing matches every method |
| `path` | exact path, or a pattern: `*` is one segment, `**` is any number of segments |
| `query` | `key=value` pairs that must be in the request query; a key without a value only has to be present |
| `operationName` | GraphQL only: the rule matches a request whose operation has this name (`*` allowed, for example `Get*`). The name comes from `operationName` in the body, else from the query document; a batch matches when one of its operations matches. Without the field the rule ignores GraphQL |
| `respond` | the answer: `status`, `headers`, `body` (or `bodyFile`, a path next to the set file for a large body), `delay` in seconds |
| `patch` | the request goes to the real host, then each operation sets (`value`) or removes (`remove: true`) a key path in the JSON response |

The first enabled rule that matches wins. The Network list shows a GraphQL request by its operation name with a `query`, `mutation` or `batch` tag; a response with an `errors` array counts as failed even with status 200.
