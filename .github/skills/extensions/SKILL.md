---
name: extensions
description: "Add or change anything the user configures through .devhub/ files: quick actions, git pills, scripts with inputs, launch profiles, simulator status script, custom tabs, the script line protocol; and how to extend the schema in code (Core/Config types, decoder, merge, ActionCatalog, placements, docs/extensions.md). Load for any request like 'add an action', 'add a script', 'add a profile', 'custom tab', 'new config field', 'new placement'."
---

# Extensions

The schema is `docs/extensions.md`. It is normative: the decoder in `DevHub/Core/Config/` must match it, and a change to one is a change to both in the same commit. Examples live in `docs/examples/devhub/`.

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

The pieces, in dependency order:

| Piece | File | Role |
|---|---|---|
| Schema types | `Core/Config/ProjectConfig.swift` (project.json), `Core/Config/ActionConfig.swift` (`Placement`, `ActionRun`, `ActionInput`, `ActionConfig`, `TabConfig`) | `Codable`, `Hashable`, `Sendable`; every field optional or with a default; tolerant decoding (unknown keys ignored) |
| Helpers | `Core/Config/ProjectConfig+Helpers.swift` | `bundleID(scheme:configuration:detected:)`, `visibleSchemes(detected:)`, `EffectiveProject` (name, kind, container, schemes, scheme, configuration, base branch, bundle ID) |
| Models | `Core/Config/ConfigModels.swift`, `Core/Models/CatalogAction.swift`, `ActionContext.swift`, `ActionResult.swift`, `ScriptView.swift` | layers, origins, issues, `ResolvedConfig`, `CatalogAction`, `ActionContext`, `PendingRun`, the `view` directive shapes |
| Script header parser | `Core/Parsers/ScriptHeaderParser.swift` | `# devhub: key = value` lines to `ActionConfig` plus problems |
| Directive parser | `Core/Parsers/ScriptDirectiveParser.swift` | `@devhub {...}` to `ScriptLine` (`plain`, `directives`, `unknown`, `invalid`) |
| Placeholders | `Core/Parsers/PlaceholderExpander.swift` | `{name}` expansion, optional percent-encoding for URLs |
| Decode and merge | `Core/Config/ConfigDecoding.swift`, `ConfigMerge.swift` | error text with key path; three layers to one `ResolvedConfig`; `project.json` merges deep, actions and tabs by `id` |
| Example | `Core/Config/ExampleConfig.swift`, `ExampleScripts.swift` | the content of `docs/examples/devhub/` as Swift raw strings, used by "Create .devhub example" and by `MockConfigProvider`; regenerate them when the docs example changes |
| Provider and watcher | `Services/Config/ConfigProvider.swift`, `LiveConfigProvider.swift`, `ConfigWatcher.swift` | read the folders off the main actor, watch directories (`DispatchSource`) plus a 2 s fingerprint check for in-place edits and folders that appear later, debounce 300 ms |
| Stores | `Shared/ConfigStore.swift` (`resolved`, `config`, `effective`, `issues`, `reload()`), `Shared/ActionCatalog.swift`, `Shared/ActionRunner.swift` (+`+Execution`, `+Directives`), `Shared/ProjectActions.swift`, `Shared/ActionContextBuilder.swift` | catalog: `actions(for: Placement)`; runner: `request(_:item:slot:)`, `run(_:item:inputs:)`, `pending(in:)`, results, progress |
| Views | `Features/Actions/` (`ActionPrompt`, `ActionInputField`, `ActionResultView`, `ScriptViewRowView`), `Features/Home/` (`QuickActionsSection`, `ScriptsSection`, `ScriptRow`) | prompt with inputs and confirm, result area, rows |

Render an action at a new place: ask the catalog (`catalog.actions(for: .worktreesRow)`), call `runner.request(action, item: ActionItemContext(worktreePath: path), slot: "worktrees.row:\(path)")`, and show `ActionPrompt(pending:)` in the row when `runner.pending(in: slot)` is not nil. The item fields reach the script as `DEVHUB_WORKTREE_PATH`, `DEVHUB_BRANCH`, `DEVHUB_SIMULATOR_UDID`, `DEVHUB_SIMULATOR_NAME`, `DEVHUB_ROW_ID`.

Steps for a new field or placement:

1. Add the field to the schema type with a default. Keep decoding tolerant: unknown keys are ignored, a wrong type is an error with the key path in the message.
2. Add it to `docs/extensions.md` with type, default and effect, and to an example under `docs/examples/devhub/`.
3. Render it: a new `Placement` case gets one call site in the view that owns that slot, through `ActionCatalog`.
4. Run `Scripts/build.sh`, then load the example folder in the app and check the item appears. Add a changelog line.

## Picker inputs

`branch` and `worktree` inputs are searchable pickers over live data (`GitStore.branchNames`, `WorktreesStore.worktrees`), `choice` and `scheme` use `SearchablePicker` over the options or the schemes. The picker falls back to a text field while its list is empty. `branch` with `default: "current"` starts with the branch of the checkout chosen in the Git tab (`session.activeBranch`); `cwd: checkout` and `DEVHUB_CHECKOUT_PATH` follow the same checkout. `simulator` is still a text field until M4. The code is `Features/Actions/ActionInputField.swift` and `Shared/ActionContextBuilder.swift`.

## Context variables

Every run gets `DEVHUB_PROJECT_PATH`, `DEVHUB_PROJECT_NAME`, `DEVHUB_CHECKOUT_PATH`, `DEVHUB_MAIN_PATH`, `DEVHUB_BRANCH`, `DEVHUB_BASE_BRANCH`, `DEVHUB_SCHEME`, `DEVHUB_CONFIGURATION`, `DEVHUB_BUNDLE_ID`, `DEVHUB_SIMULATOR_UDID`, `DEVHUB_SIMULATOR_NAME`, `DEVHUB_APP_PATH`, `DEVHUB_WORKTREE_PATH`, `DEVHUB_INPUT_<KEY>`, `DEVHUB_CONFIG_DIR`, `DEVHUB_ROW_ID`, `DEVHUB_VERSION`. An empty value is set to an empty string, never left unset, so scripts can use `set -u`.

## Directives

`@devhub ` plus one JSON object per line: `progress`, `toast`, `copy`, `open`, `notify`, `refresh`, `error`, `app`, `view` (`rows`, `keyValues`, `text`). An unknown directive is shown as a plain line with a "unknown directive" tag, never an error.

## Rules

- The app never writes into `.devhub/` except "Create example" from Settings, which writes the content of `docs/examples/devhub/` (embedded as Swift strings in `Core/Config/ExampleConfig.swift`) into `<repo>/.devhub` and refuses when the folder exists.
- A built-in action and a config action look the same in the UI. Built-ins have ids `builtin.<name>` and can be hidden or reordered through `home.quickActions`.
- Nothing project-specific goes into Swift. When a request sounds project-specific ("add a button that resets the staging account"), the answer is a script or an action file, plus a schema change only when the schema cannot express it.
