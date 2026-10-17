---
name: extensions
description: "Add or change anything the user configures through .devhub/ files: quick actions, git pills, scripts with inputs, launch profiles, simulator status script, custom tabs, the script line protocol; and how to extend the schema in code (Domain config models, ConfigDecoding, ConfigMergePolicy, ActionCatalogPolicy, ConfigActionsStore, placements, docs/extensions.md). Load for any request like 'add an action', 'add a script', 'add a profile', 'custom tab', 'new config field', 'new placement'."
---

# Extensions

The schema is `docs/extensions.md`. It is normative: the decoder (`Packages/DevHubKit/Sources/DevHubDomain/Models/Config/` and `Policies/`) must match it, and a change to one is a change to both in the same commit. Examples live in `docs/examples/devhub/`. After a change there, run `Scripts/generate-example-config.sh`: it rewrites `DevHubDomain/Policies/ExampleConfig.swift`.

## Add an item for a project (no code)

1. Find the layer: `<repo>/.devhub/` (shared), `~/.devhub/projects/<folder name>/` (only this user), `~/.devhub/` (every project).
2. Pick the shape:
   - a button that runs something → `actions/<id>.json` with `run`, `placements`, optional `inputs`, `confirm`, `refresh`, `when`;
   - a script the user runs from Home → an executable in `scripts/` with `# devhub:` header lines; no JSON needed;
   - a launch variant (environment variables, arguments, defaults in the app container) → `launch.profiles[]` in `project.json`;
   - a status line under a simulator → `simulators.statusScript` in `project.json`;
   - a whole tab → `tabs/<id>.json` with sections of action ids and source scripts.
3. Save. DevHub reloads on file change. A decode error shows inline with the file name and the reason; fix and save again.
4. Check the result in the Output panel: the command line, the context variables are visible in the hint of the action, the directives are listed as "directive" lines.

Script skeleton:

```sh
#!/bin/zsh
# devhub: title = My task
# devhub: subtitle = What it does in one line
# devhub: icon = terminal
# devhub: input = name, Name, text, default
# devhub: placements = home.scripts, git.pills
set -euo pipefail
echo "@devhub {\"progress\": \"Working on $DEVHUB_BRANCH\"}"
# work
echo "@devhub {\"toast\": \"Done\"}"
```

Rules for scripts: `chmod +x`; use the `DEVHUB_*` variables instead of hardcoding paths; print `@devhub {"error": "…"}` for a failure the exit code does not show; keep a status script under 5 seconds.

## Extend the schema (code)

Paths are under `Packages/DevHubKit/Sources/`. The pieces, in dependency order:

| Piece | File | Role |
|---|---|---|
| Schema types | `DevHubDomain/Models/Config/` (`ProjectConfig`, `XcodeConfig`, `GitConfig`, `LaunchProfile`, `ActionConfig`, `ActionRun`, `ActionInput`, `ActionCondition`, `Placement`, `TabConfig`, …) | `Codable`, `Hashable`, `Sendable`, one type per file; every field optional; unknown keys ignored |
| Resolved models | `DevHubDomain/Models/Config/` (`ConfigLayer`, `ActionOrigin`, `ResolvedAction`, `ResolvedConfig`, `ConfigIssue`, `CatalogAction`, `ActionContext`, `ActionItemContext`, `EffectiveProject`, `ScriptView`) | three layers merged to one config; built-in and config actions in one catalog |
| Pure rules | `DevHubDomain/Policies/` (`ConfigDecoding`, `ConfigMergePolicy`, `ScriptHeaderParser`, `ScriptDirectiveParser`, `PlaceholderExpander`, `ActionCatalogPolicy`, `ActionContextPolicy`, `EffectiveProjectPolicy`) | error text with the key path; `project.json` merges deep, actions and tabs by `id`; `actions(for: Placement)`; context variables |
| Ports | `DevHubDomain/Repositories/` (`ConfigRepository`, `ScriptRunning`, `ToolLocating`) | load, watch, create the example; run a script as a stream; check a tool |
| Live adapters | `DevHubData/Config/` (`FileConfigRepository`, `ConfigFolderReader`, `ConfigWatcher`, `ExampleConfigWriter`, `ShellScriptRunner`), `DevHubData/Workspace/PathToolLocator` | read folders off the main actor, poll for changes, stream through `ShellRunner` |
| Mocks and spies | `DevHubMocks` (`MockConfigRepository`, `MockScriptRunner`, `MockToolLocator`), `DevHubTestSupport` (`SpyConfigRepository`, `SpyScriptRunner`, `SpyToolLocator`) | previews and tests |
| Stores | `DevHubPresentation/Shared/ConfigStore.swift` (`resolved`, `reload()`, `effective(…)`), `Features/ConfigActions/ConfigActionsStore.swift` (+`Execution`, `+Directives`) | `actions(for:)`, `request(_:item:slot:)`, `request(id:item:slot:)`, `pending(in:)`, `runs`, `progress` |
| Views | `Features/ConfigActions/Views/` (`ConfigActionBar`, `ConfigActionMenuItems`, `ConfigActionPrompt`, `ConfigActionPromptSlot`, `ConfigActionInputField`, `ConfigActionResults`, `ConfigActionResultView`, `ScriptViewRowView`), `Features/Home/` and `Features/Scripts/` | prompt with inputs and confirm, result area, tiles and rows |

Render actions at a new place:

- A bar or a toolbar: `ConfigActionBar(placement: .logsToolbar, item: ActionItemContext(simulatorUDID: udid))`. It shows the buttons, the prompt and the result area.
- A row: the screen builds `ConfigActionItemMapper.models(for: configActions.actions(for: .worktreesRow), isRunning: configActions.isRunning)` and passes them to the row mapper as `configActions:`. The row puts `ConfigActionMenuItems(items: model.configActions, onRun: onConfigAction)` in its menu. The screen calls `configActions.request(id:item:slot:)` with `ActionItemContext(branch:worktreePath:rowID:)` and the slot `Placement.worktreesRow.slot(for: path)`, and draws `ConfigActionPrompt` under the row while `configActions.pending(in: slot)` is not nil.

Pull request rows pass the closure through `PullRequestDetailActions.runConfigAction`, which sends `ActionItemContext(branch:rowID:pullRequestNumber:pullRequestURL:)` with the slot `Placement.pullRequestsRow.slot(for: number)`.

The item fields reach the script as `DEVHUB_WORKTREE_PATH`, `DEVHUB_BRANCH`, `DEVHUB_SIMULATOR_UDID`, `DEVHUB_SIMULATOR_NAME`, `DEVHUB_ROW_ID`, `DEVHUB_PR_NUMBER`, `DEVHUB_PR_URL`.

Steps for a new field or placement:

1. Add the field to the schema type, optional. Keep decoding tolerant: unknown keys are ignored, a wrong type is an error with the key path in the message. Add a Domain test in `Tests/DevHubDomainTests/`.
2. Add it to `docs/extensions.md` with type, default and effect, and to an example under `docs/examples/devhub/`; run `Scripts/generate-example-config.sh`.
3. Render it: a new `Placement` constant gets one call site in the screen that owns that slot. Add a mapper test that the items reach the row model.
4. Run `Scripts/build.sh` and `Scripts/test.sh`, then load the example folder in the app (`DEVHUB_PROJECT=<repo> DEVHUB_OPEN_PANEL=1 DEVHUB_TAB=<tab> DEVHUB_SNAPSHOT=<file>.png`, see `build-and-run`). Add a changelog line.

## Picker inputs

`branch`, `worktree` and `simulator` inputs are searchable pickers over live data (`GitStore.localBranchNames`, `WorktreesStore.worktrees`, `SimulatorsStore.all` with booted simulators first), `choice` and `scheme` use `SearchablePicker` over the options or the schemes. The picker falls back to a text field while its list is empty. `branch` with `default: "current"` starts with the branch of the checkout chosen in the Git tab; `cwd: checkout` and `DEVHUB_CHECKOUT_PATH` follow the same checkout. `simulator` with `default: "target"` starts with the target simulator. The code is `Features/ConfigActions/Views/ConfigActionInputField.swift` and `DevHubDomain/Policies/ActionContextPolicy.swift`.

## Context variables

Every run gets `DEVHUB_PROJECT_PATH`, `DEVHUB_PROJECT_NAME`, `DEVHUB_CHECKOUT_PATH`, `DEVHUB_MAIN_PATH`, `DEVHUB_BRANCH`, `DEVHUB_BASE_BRANCH`, `DEVHUB_SCHEME`, `DEVHUB_CONFIGURATION`, `DEVHUB_BUNDLE_ID`, `DEVHUB_SIMULATOR_UDID`, `DEVHUB_SIMULATOR_NAME`, `DEVHUB_APP_PATH`, `DEVHUB_WORKTREE_PATH`, `DEVHUB_INPUT_<KEY>`, `DEVHUB_CONFIG_DIR`, `DEVHUB_ROW_ID`, `DEVHUB_VERSION`. An empty value is set to an empty string, never left unset, so scripts can use `set -u`.

## Directives

`@devhub ` plus one JSON object per line: `progress`, `toast`, `copy`, `open`, `notify`, `refresh`, `error`, `app`, `view` (`rows`, `keyValues`, `text`). An unknown directive is shown as a plain line with a "unknown directive" tag, never an error.

## Rules

- The app never writes into `.devhub/` except "Create .devhub Example" from Settings, which writes the content of `docs/examples/devhub/` (embedded as Swift strings in `DevHubDomain/Policies/ExampleConfig.swift`, generated by `Scripts/generate-example-config.sh`) into `<repo>/.devhub` and refuses when the folder exists.
- A built-in action and a config action look the same in the UI. Built-ins have ids `builtin.<name>` and can be hidden or reordered through `home.quickActions`.
- Nothing project-specific goes into Swift. When a request sounds project-specific ("add a button that resets the staging account"), the answer is a script or an action file, plus a schema change only when the schema cannot express it.
