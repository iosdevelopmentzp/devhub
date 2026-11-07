# Custom tabs

A custom tab is a tab that you define in a JSON file in `.devhub/tabs/`. It has no Swift code of its own. It shows sections with action rows and sections that a script fills. A custom tab is a sub-tab of the Utils tab by default; `"placement": "bar"` or a right-click puts it in the tab bar after the built-in tabs ([Utils](utils.md#tab-layout)).

Code: `Packages/DevHubKit/Sources/DevHubPresentation/Features/CustomTabs/`, `Features/ConfigActions/`, `DevHubDomain/Policies/CustomTabPolicy.swift`, `Shell/TabItemMapper.swift`, `Shell/TabLayout.swift`.

## What it shows

### Tab bar and header

- The tab button uses `title` and `icon` (default icon `square.grid.2x2`). It sits in the sub-tab row of Utils, or in the tab bar with `"placement": "bar"`. A right-click on the button moves it to the other place; the choice is saved for the user and wins over the file.
- The search field in the toolbar uses `searchPrompt` (default "Search <title>").
- A tab with `inputs` shows them in a bar under the toolbar, one field per input, with the same controls as action inputs. The values are saved per project and tab, and every action and source script of the tab gets them as `DEVHUB_INPUT_<KEY>` and `{key}`. An input marked `recent: true` has a clock menu with the last 12 values and "Forget" for each.

### Sections

The tab shows its `sections` in file order. One section in the file can give two sections on screen: one for `actions` and one for `source`.

| Section kind | What it shows |
|---|---|
| Actions (`sections[].actions`) | One row per action id. A config action row has the same look and controls as a script row on Home: icon, title, subtitle, file name, last run, Run, Stop, overflow menu, inputs and the result view. A built-in action (`builtin.*`) is a plain row with its icon, title and subtitle. An id that does not exist shows "Unknown action <id>" in red. A config action whose `when` condition does not match is hidden. A section where every action is hidden is not shown |
| Source (`sections[].source`) | The output of a script. The header shows "read 5 min ago" or a spinner, and a refresh button. The body shows the `view` of the last run: key-value pairs, monospaced text, or rows with tags and buttons. A failed run shows its message in red. A missing script shows "No script <path> in the .devhub folders" |
| Actions (extra) | Actions with the placement `tab.<id>` that no section lists. DevHub adds them in a last section called "Actions" |
| Recent | The last 30 texts that `copy` actions of this tab put on the clipboard, for this project, newest first: the text (click to copy), the action title and the time. Hover shows Resend (copies again and opens the target again) and Remove; Clear in the header drops the list of this tab. The section is hidden while the list is empty |

A tab without sections shows "This tab has no sections. Add actions or a source script in .devhub/tabs/<id>.json."

The search field in the toolbar filters action rows by title and subtitle, and source rows by title, subtitle and tag text.

## Actions

### Action rows

| Control | What it does | Command |
|---|---|---|
| Run | Runs the action. When it has `inputs` or `confirm`, the prompt opens under the row. A `copy` action shows the rendered text under its inputs and the button says Copy | the `run` of the action (see [`run`](../extensions.md#31-run)) |
| Confirmation | The action's `confirm`, or the `confirm` of the chosen option of a `choice` input of the action or of the tab, which wins. An action without inputs asks too when the chosen tab option has one | — |
| Stop | Cancels a running script | — |
| Edit in `<editor>` (menu) | Opens the script file in the editor from Settings | `open -a <editor> <file>` |
| Reveal in Finder (menu) | Shows the script file | — |
| A built-in row | The same as the Home tile | see the Home page |

### Source sections

1. DevHub finds the script by its file name: `source.script` = `scripts/list-devices.sh` means the header script action `script:list-devices`. The script must be a file in the `scripts/` folder of one of the `.devhub` layers.
2. It runs the script like a script action, with the context variables and the default input values. A file without the executable bit runs through `/bin/zsh`.
3. The last `@devhub {"view": …}` line of the run fills the section.
4. `source.refresh` decides when the script runs:

   | Value | When |
   |---|---|
   | `onOpen` (default) | Each time the tab appears and each time the panel opens on it |
   | `manual` | Only with the refresh button. Before the first run the section says "Press refresh to run <file>." |
   | a number of seconds | When the tab appears, then every N seconds while the tab is on screen. The minimum is 5 seconds. A run is skipped while the previous one still runs |

The refresh button always runs the script again.

### Row buttons from a `view`

A `view` row can have its own `actions`. Each one is a button in the row.

1. The button runs the `run` of the row action: `script`, `command`, `terminal` or `open`.
2. A `script` path starts at the `.devhub` folder of the source script.
3. The row `id` reaches the action as `DEVHUB_ROW_ID` and `{row_id}`.
4. With `confirm`, an inline confirmation opens under the row first.

Example of a source script line:

```sh
echo '@devhub {"view": {"rows": [{"id": "sim-1", "title": "iPhone 17", "subtitle": "iOS 26", "tags": [{"text": "booted", "tint": "green"}], "actions": [{"title": "Open", "run": {"open": "example://home"}}]}]}}'
```

### Keys

The tabs of the tab bar get ⌘1 to ⌘9 in order. There are 9 built-in tabs, so a custom tab in the bar has a shortcut only when a built-in tab was moved to Utils. Sub-tabs of Utils have no shortcut; the ⌘K palette opens every tab by name.

## Config

A tab file:

```json
{
  "id": "qa",
  "title": "QA",
  "icon": "wrench.and.screwdriver",
  "searchPrompt": "Search QA tools",
  "sections": [
    { "title": "Project", "actions": ["clean-derived-data", "open-ci", "script:regenerate-resources"] },
    { "title": "Booted simulators", "source": { "script": "scripts/list-devices.sh", "refresh": "onOpen" } }
  ]
}
```

| Field | Effect | Reference |
|---|---|---|
| `id` | The tab id, the `tab.<id>` placement, and the saved tab `tab.<id>` | [Custom tabs](../extensions.md#8-custom-tabs) |
| `title`, `icon`, `searchPrompt` | The tab button and the search field | [Custom tabs](../extensions.md#8-custom-tabs) |
| `placement` | `utils` (default) or `bar`: where the tab starts | [Custom tabs](../extensions.md#8-custom-tabs) |
| `inputs` | The shared inputs in the bar under the toolbar | [Custom tabs](../extensions.md#8-custom-tabs), [Inputs](../extensions.md#32-inputs) |
| `sections[].title` | The section header | [Custom tabs](../extensions.md#8-custom-tabs) |
| `sections[].actions` | Action ids: config actions, `script:<name>`, `builtin.*` | [Custom tabs](../extensions.md#8-custom-tabs), [`project.json`](../extensions.md#2-projectjson) (the built-in ids) |
| `sections[].source.script`, `.refresh` | The source script and when it runs | [Custom tabs](../extensions.md#8-custom-tabs) |
| Actions with `placements: ["tab.<id>"]` | Rows in the extra "Actions" section | [Placements](../extensions.md#33-placements) |
| The `view` directive | The content of a source section | [Script line protocol](../extensions.md#7-script-line-protocol) |

Tabs merge by `id` across the layers, like actions: the user layer wins over the project layer, and the project layer wins over the global layer. A tab with the same `id` replaces the whole tab of the lower layer; its fields do not merge. See [Where files live](../extensions.md#1-where-files-live).

A header script has the placement `home.scripts` by default, so a source script also shows as a row on Home. Add `# devhub: placements = palette` to its header to keep it off Home. The example tab in `docs/examples/devhub/` does this.

## Saved preferences

A custom tab has no store of its own (`docs/STATUS.md`, decision 31). It shares the keys of the config actions:

| Key | What it keeps |
|---|---|
| `navigator.selection` | The selected tab of the tab bar. A custom tab is saved as `tab.<id>` |
| `utils.selection` | The selected sub-tab of Utils, with the same `tab.<id>` form |
| `tabs.layout` | The tabs the user moved with a right-click: `tab.<id>` to `bar` or `utils` |
| `configActions.lastRun` | The last run time per project and action. A source section shows it as "read 5 min ago". Home shows the same time for the same script |
| `configActions.inputs` | The remembered inputs (`remember: true`) per project and action |
| `configActions.tabInputs` | The values of the shared inputs per project and tab |
| `configActions.recentInputs` | The recent values (`recent: true`) per project, action or tab, and input key |
| `configActions.copyHistory` | The Recent list of `copy` actions: 30 per project, with the text, the action, the tab and the open target |

The last `view` of a source section lives in memory. After a restart the section is empty until the script runs again.

## Limits

- A custom tab has a keyboard shortcut only in the tab bar, and only while its position is ⌘9 or lower.
- A source script is found by its base file name. A script outside a `scripts/` folder is "missing", even when `source.script` points to a real file.
- The run state of a source script is shared with Home: a run from Home changes the "read …" time of the section.
- A timed refresh runs only while the tab is on screen and the panel is open.
- When the selected custom tab is removed from the config, the panel shows Home. When a selected sub-tab of Utils is removed, Utils shows its first sub-tab.
