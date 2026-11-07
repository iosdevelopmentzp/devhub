# Logs tab

The Logs tab streams the system log of the app from one or more booted simulators. Each simulator gets its own stream with its own filters.

Source: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Logs/`, `DevHubData/Logs/`, `DevHubDomain/Policies/AppLogPredicatePolicy.swift`, `LogTargetPolicy.swift`.

Related pages: [Simulators](simulators.md).

## What it shows

1. **The chip bar.** One chip per stream: "<simulator name> · booted" or "· off". The dot is green while the stream runs, red after an error, gray when stopped. The `+` menu lists booted simulators that have no stream yet.
2. **The toolbar** of the selected stream:
   - the **Process** field and the **Subsystem** field;
   - **Start** or **Stop**, and a green "live" label while the stream runs;
   - the level filter: All, Info+, Default+, Errors;
   - "<shown> of <total> lines", and "<n> dropped" when the list hit its limit;
   - **Pause**, **Copy**, **Clear**;
   - config actions with the `logs.toolbar` placement.
3. **The line list.** Each line shows the time, the level (Debug, Info, Default, Error, Fault), the subsystem and category, and the message. Error and Fault messages are red or purple. The list follows the newest line unless the stream is paused.

The search field in the toolbar filters lines by message and category.

When there is no stream, the tab says: "Boot a simulator and press + to stream its logs."

When the tab opens and there is no stream yet, DevHub adds one for the target simulator when it is booted, else for the first booted simulator. It does not start it.

## Actions

| Action | What it does | Command |
|---|---|---|
| `+` (add stream) | Adds a stream for a booted simulator, selects it and starts it | see "Start" |
| Chip click | Selects the stream | none |
| Chip close | Stops and removes the stream | none |
| Start | Starts the stream | `xcrun simctl spawn <udid> log stream --style ndjson --level debug [--predicate <predicate>]` |
| Stop | Stops the `log stream` process | none |
| Process field | Filters by process name. Saved for this stream | changes the predicate on the next Start |
| Subsystem field | Filters by subsystem. When set, it replaces the process filter | changes the predicate on the next Start |
| Level filter | Hides lines below the chosen level. Saved for this stream | none |
| Pause | Freezes the list. New lines wait. The title shows "Paused · <n> new". Resume shows the waiting lines | none |
| Copy | Copies the visible lines as `<level>\t<category>\t<message>` | none |
| Clear | Removes all lines of the stream | none |
| Start Again | Shown after the stream stopped with an error | the Start command |
| Config actions | Actions with the `logs.toolbar` placement. They get the simulator of the stream as context | the action's `run` |

**Stream App Logs** in a simulator row menu opens this tab and starts a stream for that simulator.

### The predicate

`AppLogPredicatePolicy` builds the predicate:

1. With a subsystem: `subsystem == "<subsystem>"`.
2. Else, with a process: `process == "<process>"`.
3. Else: no predicate.

When both fields are empty on Start, DevHub finds the process name first:

1. `xcrun simctl get_app_container <udid> <bundle ID> app`, then `CFBundleExecutable` from its `Info.plist`. The bundle ID is the same as in the identity panel ([Device identity](device-identity.md#the-bundle-id)).
2. When the app is not installed, the scheme of the project.
3. When both are empty, the stream does not start: "No process name. Type one in the Process field."

DevHub writes the found name into the Process field.

### Line handling

1. DevHub parses each JSON line of `log stream`. Lines without `eventMessage` are skipped.
2. `LogRedactor` masks bearer tokens, JWTs, and values after keys such as `authorization`, `token`, `password`, `secret` and `api_key`. The mask is `•••`.
3. DevHub adds new lines to the list every 150 ms.
4. A stream keeps the last 5,000 lines. Older lines are dropped and counted.
5. Nothing is saved to disk.
6. The Output panel shows the `log stream` command, but not its lines.

## Config

| Field | Effect here | Schema |
|---|---|---|
| `logs.process` | The process filter of a new stream | [§2](../extensions.md#2-projectjson) |
| `logs.subsystem` | The subsystem filter of a new stream | [§2](../extensions.md#2-projectjson) |
| actions with `logs.toolbar` | Buttons in the toolbar | [§3.3](../extensions.md#33-placements) |

The config gives only the defaults of a new stream. A stream that exists keeps its own fields.

## Saved preferences

| Key | Value | Written by |
|---|---|---|
| `logs.streams` | Per stream: simulator UDID, simulator name, process, subsystem, level | `LogsStore` |
| `logs.selected` | UDID of the selected stream | `LogsStore` |

The streams come back after a restart, stopped. Pause, the lines and the running state are not saved.

## Limits

1. Only lines from `os_log` and `Logger` appear. `print()` output does not reach the system log.
2. A stream can start only on a booted simulator. A chip of a shut-down simulator shows "off".
3. A change to the Process or Subsystem field applies on the next Start, not to a running stream.
4. The `logs` refresh target of actions does nothing yet.
5. The list keeps 5,000 lines per stream.
