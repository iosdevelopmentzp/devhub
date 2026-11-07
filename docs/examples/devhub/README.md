# Example `.devhub/` folder

Copy this folder into a project as `.devhub/` and adjust the values. Every field is explained in `docs/extensions.md`; `docs/customization.md` maps a need to the mechanism.

- `project.json`: how the project builds and runs, base branch, worktree rules, launch profiles with their mock server upstream, the launch identity, the network mocks, log filter, Home grid order.
- `actions/`: buttons with placements, inputs and confirmation.
- `scripts/`: executables. A script with a `# devhub:` header becomes a row on Home without a JSON file. The helper scripts that an action, a tab or `simulators.statusScript` runs have `placements = palette`, so Home does not list them twice.
- `tabs/`: `qa.json`, a custom tab built from actions and a source script; `chat.json`, a tab of chat commands with shared inputs (environment and user ID), `copy` actions that put the rendered command on the clipboard and open the channel, and a Recent list with Resend.
