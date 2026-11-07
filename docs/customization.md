# Customizing DevHub without code

This page is the map of everything a project can change through its `.devhub/` folder, written for a person or an AI agent that has to decide "do I need code for this?". The answer is "no" far more often than it looks. The exact fields are in [`docs/extensions.md`](extensions.md) (the normative schema); a full example folder is in [`docs/examples/devhub/`](examples/devhub/). When the schema cannot express a need, the `extensions` skill (`.github/skills/extensions/SKILL.md`) says how to extend it in code.

## 1. The three layers

| I want the change… | Put the files in | Notes |
|---|---|---|
| for the whole team, with the repository | `<repo>/.devhub/` | committed; the project layer |
| only for me, in one project | `~/.devhub/projects/<project folder name>/` | wins over the project layer |
| for every project on this Mac | `~/.devhub/` | the global layer; the other layers win |

Each layer holds `project.json` (not the global layer), `actions/*.json`, `scripts/*` and `tabs/*.json`. Items merge by `id`, `project.json` merges field by field. DevHub watches the folders and reloads on save; a broken file shows its error inline and the other files still load. Settings → "Create .devhub Example" writes the example folder into a project.

## 2. From a need to a mechanism

| I want to… | Mechanism | Where it is described |
|---|---|---|
| run a command or script from a button | an **action** (`actions/<id>.json`) with `run` = `script`, `command`, `terminal` or `open` | extensions.md §3 |
| add a script without writing JSON | an executable in `scripts/` with `# devhub:` header lines (title, icon, inputs, placements, confirm) | §4 |
| ask for values before the run | `inputs` on the action or `# devhub: input =` in the header: text, number, toggle, choice, branch, worktree, simulator, scheme, file, folder; `remember: true` keeps the last value | §3.2 |
| put the button in a specific place | `placements`: Home grid, Home scripts list, Git header pills, branch and worktree row menus, run bar, simulator row menu, App Data panel, Logs and Network toolbars, pull request rows, the command palette, a custom tab | §3.3 |
| show the button only when it makes sense | `when`: git clean or dirty, target simulator booted, a tool installed, `kind` xcode or command, host github or gitlab | §3 |
| ask before a destructive run | `confirm: "text"` (inline, no alert); `confirm` on one option of a `choice` input asks only for that value | §3, §3.2 |
| refresh a tab after the run | `refresh: ["git", "worktrees", "simulators", …]` | §3 |
| open a URL built from the branch, ticket or request | `run: { "open": "https://…/{branch}" }` with placeholders | §3.1, §3.4 |
| put a rendered text on the clipboard and open the place to paste it | `run: { "copy": "{env} coins {user}", "open": "slack://…" }`; the prompt shows the text live; a custom tab keeps the last 30 with Resend | §3.1, §8 |
| share inputs between every row of a tab, with recent values | `inputs` on the tab (`tabs/<id>.json`), `recent: true` on a text or number input | §8, §3.2 |
| know the project, branch, simulator, app or request inside a script | the `DEVHUB_*` variables (project path, checkout, branch, base branch, scheme, bundle ID, simulator UDID, name, state and kind, app path, containers, profile, host, PR number and URL, inputs) | §3.4 |
| make a script talk back to DevHub | `@devhub {…}` lines: `progress`, `toast`, `copy`, `open`, `notify`, `refresh`, `error`, `app`, `state`, `view` | §7 |
| render a list, a key-value block or text from a script | the `view` directive with `rows` (title, subtitle, tags, row actions), `keyValues` or `text` | §7 |
| add a whole tab | `tabs/<id>.json` with sections of action ids and sections rendered by a script's `view` | §8 |
| order or hide the tiles on Home | `home.quickActions` with built-in and config ids | §2 |
| build and run a non-Xcode project | `kind: command` with `build.command` and `run.command`; `@devhub {"app": …}` hands the app to DevHub | §2 |
| pick the scheme, configuration, bundle ID or Xcode of a project | `xcode.scheme`, `xcode.schemes`, `xcode.configuration`, `xcode.bundleID`, `xcode.bundleIDs`, `xcode.developerDir` | §2 |
| launch the app with an environment, arguments or defaults | `launch.profiles[]` (`env`, `args`, `defaults`, `storage`, `upstream`, `production`, `cleanInstall`, `tint`) | §5 |
| give each launch a device or account ID | `launch.identity` (variable, kept variable, args, prefix, clean install rule, hook marker) | §2, [device identity](features/device-identity.md) |
| show what the running app reports (ID, environment, host, user, version, tags) | `simulators.statusScript` printing a `state` directive | §6, §7 |
| redirect the app to the mock server | `network.baseURLVariable`, `network.mocksFolder`, mock set files | §2, §9 |
| set git rules: remote, base branch, protected branches, ticket pattern and link, worktree folder and bootstrap | `git.*` | §2 |
| list the Jira tickets of the project in Utils → Tickets, with Start, Move to and a branch name | `tracker.*` (`kind`, `project`, `statuses`, `startStatus`, `filter`, `branchFormat`); the `jira` tool of jira-cli with your own login | §2, [utils](features/utils.md#tickets) |
| tune pull requests: targets, template, stale days, hidden files, defaults | `git.pullRequests.*` | §2 |
| change which AI tool "Fix with AI" and "Write with AI" run | `ai.commands`, `ai.textCommands` | §2 |
| filter the log stream | `logs.process`, `logs.subsystem` | §2 |

## 3. Worked example: a tab of chat commands

A team bot takes slash commands in a chat channel. Nobody can send such a command through an API, so the tool prepares the text, copies it and opens the channel: the user pastes and presses Return. This needs no script: one action per command with a `copy` run, and one custom tab with the inputs that every command shares. Put the files in `~/.devhub/` when every project should see the tab, or in the project folder. The example folder `docs/examples/devhub/` holds this tab as `tabs/chat.json`, `actions/chat-coins.json` and `actions/chat-build.json`.

`tabs/chat.json`: the tab and its shared inputs. The environment is a choice whose PROD option asks before every command. The user ID keeps a menu of recent values.

```json
{
  "id": "chat",
  "title": "Chat",
  "icon": "bubble.left.and.text.bubble.right",
  "searchPrompt": "Search chat commands",
  "inputs": [
    { "key": "env", "title": "Environment", "type": "choice", "options": [{ "value": "/qabot", "title": "QA" }, { "value": "/prodbot", "title": "PROD", "confirm": "Copy a command for PROD?" }], "default": "/qabot" },
    { "key": "user", "title": "User ID", "type": "text", "recent": true, "placeholder": "the ID from the profile page" }
  ],
  "sections": [
    { "title": "Accounts", "actions": ["chat-coins"] },
    { "title": "CI", "actions": ["chat-build"] }
  ]
}
```

`actions/chat-coins.json`: one command. `{env}` and `{user}` come from the tab, `{amount}` from the action's own input. The run copies the rendered text and opens the channel.

```json
{
  "id": "chat-coins",
  "title": "Top up coins",
  "subtitle": "{env} coins {user} {amount}",
  "icon": "plus.circle",
  "placements": ["tab.chat"],
  "run": { "copy": "{env} coins {user} {amount}", "open": "slack://channel?team=T0000000&id=C0000000" },
  "inputs": [
    { "key": "amount", "title": "Coins", "type": "number", "default": 10000, "recent": true }
  ]
}
```

`actions/chat-build.json`: a command without an input of its own except the branch, a live picker over the branches of the Git tab.

```json
{
  "id": "chat-build",
  "title": "Build a branch on CI",
  "subtitle": "/cibot build {branch}",
  "icon": "hammer",
  "placements": ["tab.chat"],
  "run": { "copy": "/cibot build {branch}", "open": "slack://channel?team=T0000000&id=C0000000" },
  "inputs": [
    { "key": "branch", "title": "Branch", "type": "branch", "default": "current" }
  ]
}
```

What this gives: a tab with the environment and the user ID in a bar under the toolbar (saved per project), one row per command, the action's own inputs under the row with the rendered command shown live, a confirmation only for PROD, the text on the clipboard, the channel opened, and a "Recent" section at the bottom with the last 30 commands, Resend and Remove. A command that needs more than a template (a lookup, a file, a computed value) keeps the script shape: `run: {"script": …}` with `@devhub {"copy": …}` and `@devhub {"open": …}` lines.

What the schema still does not give: a `when` condition that reads an input, a history for actions outside a custom tab, and a `copy` run that reads the output of a command. Each would be a small schema change that other tabs can use too.

## 4. Rules for an agent that adds a customization

1. Read `docs/extensions.md` for the exact field, then `docs/examples/devhub/` for a working shape.
2. Prefer a script with a header over a JSON action, and a JSON action over a schema change. Change the schema only when the table above has no row for the need; then follow the `extensions` skill (Domain config models, `ConfigDecoding`, docs and the example in the same commit).
3. Never put a project name, host, bundle ID or token into the public repository: project knowledge lives in `.devhub/` files, sample values in docs (`docs/extensions.md` section 1, `.claude/rules/anonymity.md`).
4. Check the result in the Output panel: the command line, the `DEVHUB_*` variables in the hint of the action, the directives as "directive" lines.
