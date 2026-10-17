# ADR 002. The `.devhub` config system inside the package modules

Date: 2026-10-17. Status: accepted. Milestone: M2 of ADR 001.

## Context

The first generic app had a config system: `.devhub/` folders in three layers, actions with placements, scripts with a `# devhub:` header, a line protocol for script output, and an example folder. It lived in `DevHub/Core/Config`, `DevHub/Services/Config` and `DevHub/Shared/Action*`.

ADR 001 moved the app to the package architecture of the main DevHub: seven modules, ports, stores and Swift Testing with spies. The main DevHub has no config system, so the config system had to be rebuilt inside the modules. The schema in `docs/extensions.md` stays the same. The users of the app write that schema by hand.

## Decision

1. **Domain owns the schema and every rule.**
   - The config models in `DevHubDomain/Models/Config/` are `Codable`. This is the one exception to the rule "no `Decodable` Domain model" (STATUS decision 15). DTOs that copy each model one to one would add about 35 types and nothing else.
   - The decoding, the merge of the three layers, the header and directive parsers, the placeholders, the catalog, the context variables and the effective project are pure policies.
   - The example folder is Swift data (`ExampleConfig.files`), generated from `docs/examples/devhub/` by `Scripts/generate-example-config.sh`.
2. **Three ports carry every side effect.**
   - `ConfigRepository`: load, watch, create the example, find the folder.
   - `ScriptRunning`: run a script or a command as a stream of lines and an exit code.
   - `ToolLocating`: is a tool installed.
   - Their live adapters are in `DevHubData/Config/` and `DevHubData/Workspace/PathToolLocator`. The watcher polls with an injected interval, so the tests run fast.
3. **Two stores.**
   - `ConfigStore` (Shared) loads and watches the config of the selected project and computes the effective project from the config plus the detected values.
   - `ConfigActionsStore` (Features/ConfigActions) runs actions: prompt for inputs and confirmation, the context variables, the stream to the Output panel, the directives, the footer progress, the last run, the remembered inputs.
   - The two stores reach other features only through lookup protocols (`CheckoutContext`, `WorktreeLookup`, `BuildLookup`) and `AppEvents` (`configChanged`, `refreshRequested`).
4. **Placements are rendered by the screen that owns them.**
   - A bar or a toolbar uses `ConfigActionBar(placement:item:)`.
   - A row gets `configActions` in its model and an `onConfigAction` closure. The screen draws the prompt under the row for the slot `<placement>:<row id>` (STATUS decision 17).
   - The row placements give the script the row context: branch, worktree path, simulator, row ID.
5. **Debug switches drive the runs headless**: `DEVHUB_RUN_ACTION`, `DEVHUB_REQUEST_ACTION`, `DEVHUB_SHOW_OUTPUT`, next to the snapshot switches of M1.

## Consequences

- The sample scripts of the first generic app (`ScriptsStore`, `MockData.scripts`) are gone. Home shows the actions and scripts of the selected project only.
- A project without a `.devhub` folder still works: every field has a detected default, and Settings offers "Create .devhub Example".
- Not done in M2:
  - custom tabs and the command palette come in M7;
  - the simulator status script comes in M5;
  - `pullRequests.row` comes with the Pull Requests tab in M4;
  - the `network.toolbar` placement is not in the schema, and adding it waits for the owner.
- Tests: about 90 new tests over spies and temporary folders. The suite has about 1,570 tests.
