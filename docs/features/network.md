# Network tab

The Network tab shows the HTTP requests of the app on one simulator. It can also answer or change those requests with mock rules.

DevHub does this with a small HTTP server on this Mac. We call it the mock server. DevHub launches the app with the URL of this server in an environment variable. The app sends its requests to the server, and the server forwards them to the real server of the launch profile. We call the real server the upstream.

Source: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Network/`, `DevHubData/Network/`, `DevHubDomain/UseCases/RelaunchWithMocksUseCase.swift`, `MockLaunchPreparation.swift`, `DevHubDomain/Policies/Mock*.swift`, `GraphQLParser.swift`, `JSONPatcher.swift`.

Related pages: [Simulators](simulators.md), [Device identity](device-identity.md).

## What it shows

1. **The toolbar:**
   - the simulator picker (booted simulators only);
   - the filter: All, Failed (status 400 or more, an error, or a GraphQL `errors` array), Slow (longer than 1 s);
   - the count of shown requests;
   - **Pause** and **Clear**.
2. **The mock server bar.** It shows only when `network.baseURLVariable` is set:
   - the mode: Off, Passthrough, Mock;
   - the mock set picker (Mock mode only);
   - the **Rules** button, which opens the rule editor in place of the list;
   - **Apply & Relaunch**. It is prominent when the chosen mode or set differs from the running server;
   - the server status line, for example "Port 51234 → api.staging.example.com", "Server off" or "Server failed";
   - an info icon. Its hint says that only requests to the base URL in `network.baseURLVariable` pass through DevHub, that a production profile cannot be mocked, and that a change of the mode or the set needs a relaunch;
   - the app status line (see "App status line" below);
   - the last error in red.
3. **The request list**, newest first. Each row shows:
   - the method tag;
   - the path, or for GraphQL the operation name with a `query`, `mutation` or `batch of <n>` tag;
   - the host;
   - a `via DevHub` tag (forwarded) or a `mocked` tag (a rule answered or changed it);
   - a red "<n> GraphQL errors" tag when the response has an `errors` array;
   - the status, the duration (orange when slow) and the time.
4. **The request details**, under a row after a click:
   - the URL (click to copy) and the status line;
   - the GraphQL operations, their errors and their variables;
   - the request body and the response body (JSON is formatted);
   - the request headers and the response headers.

The header search filters by method, path, status, host and GraphQL operation name.

### Empty states

| Situation | Message |
|---|---|
| No `network.baseURLVariable` | "Network mocks are off for this project" and how to set the variable |
| No booted simulator | "No simulator booted" |
| The server is off for the chosen simulator | "Mock server is off": start Passthrough and relaunch the app |
| The server runs, no request yet | "Waiting for requests…" |
| A filter hides every request | "No failed requests" or "No slow requests" |

### App status line

The bar checks that the app really talks to the server. The line shows one of these:

| Line | Meaning |
|---|---|
| "App goes through DevHub (<server URL>)" (green) | The last launch from DevHub used this server |
| "App not installed on this simulator" | Build & Run first |
| "Launched outside DevHub: traffic may bypass the server" | DevHub has no launch of this app on record |
| "App points to an old DevHub server (<URL>): relaunch" | The last launch used another port |
| "App reports <host>: launched without DevHub" | The status script `state` line reports a host that is not `127.0.0.1` |
| "App is on <profile>, the server forwards to <profile>: relaunch" | The profile of the app and the upstream of the server differ |

## Actions

### Request list

| Action | What it does |
|---|---|
| Simulator picker | Chooses whose requests to show. Without a choice, DevHub picks the target when it is booted, else the first booted simulator |
| Filter | All, Failed or Slow |
| Pause | Freezes the list. New requests wait and appear on resume |
| Clear | Removes the requests of this simulator from the list |
| Row click | Opens or closes the details |
| Copy as cURL | Copies `curl [-X <method>] '<url>'`, plus `-H 'Content-Type: application/json' --data-raw '<body>'` when there is a body. Headers are not included |
| Copy Response Body | Copies the raw response body |
| Mock This | Adds a Respond rule at the top of the current mock set: the method, the path without the query, the GraphQL operation name, the status, the `Content-Type` and the body of this response. Without a set, DevHub creates one called "Mocks". The rule opens in the editor |

The list keeps the last 2,000 requests per simulator. Nothing is saved to disk.

### Mock server bar

| Action | What it does |
|---|---|
| Mode | Chooses Off, Passthrough or Mock for the selected simulator. Nothing changes until Apply & Relaunch |
| Mock set | Chooses the set for Mock mode |
| Rules | Shows the rule editor instead of the request list |
| Apply & Relaunch | Starts, changes or stops the server, then launches the app again |

Apply & Relaunch (`RelaunchWithMocksUseCase`) works like this:

1. **Off:** DevHub stops the server and launches the app without the variable.
2. **Passthrough or Mock:**
   1. DevHub needs `network.baseURLVariable`, a launch profile with an `upstream` that starts with `http` or `https`, and, for Mock, a chosen set.
   2. DevHub refuses a profile with `production: true`.
   3. DevHub starts the server on `127.0.0.1`. The port comes from a hash of the simulator UDID, between 49152 and 59151. When that port is busy, the system picks one.
   4. DevHub launches the app with `<baseURLVariable>=http://127.0.0.1:<port>`.

The launch is the same as in [Install and launch](simulators.md#install-and-launch), without the install: the profile `defaults`, `open -a Simulator --args -CurrentDeviceUDID <udid>`, then `xcrun simctl launch --terminate-running-process <udid> <bundle ID> <arguments>` with the launch plan environment.

The profile of the relaunch is the profile the app reports (status script `state` line), else the profile stored in the app (`storage`), else the profile of the run bar for this simulator. The ID is the actual ID of the app ([Device identity](device-identity.md)).

A Build & Run or a launch from the identity panel also uses the server when it runs for that simulator. DevHub moves the server to the upstream of the new profile, and adds the variable. When the new profile is a production profile or has no usable `upstream`, DevHub stops the server and writes the reason to the build output.

When DevHub starts, it starts the saved servers again on their ports. It skips a server whose upstream belongs to a production profile.

### The mock server

The server (`NWMockServerRepository`, `MockExchangeHandler`) handles each request in this order:

1. A WebSocket upgrade gets status 501 "WebSocket not mocked yet".
2. DevHub finds the first enabled rule that matches (see "Rule matching" below).
3. **Respond rule:** DevHub waits for the delay, then answers with the status, headers and body of the rule. Without a `Content-Type`, DevHub adds `application/json` for a JSON body, else `text/plain; charset=utf-8`.
4. **Patch rule:** DevHub forwards the request, waits for the delay, then changes the JSON response. A response that is not JSON passes unchanged.
5. **No rule:** DevHub forwards the request to the upstream.

Forwarding details:

1. The URL is the upstream URL plus the path and query of the request.
2. DevHub drops hop headers such as `Host`, `Connection` and `Accept-Encoding`, and asks for `Accept-Encoding: identity`.
3. Redirects are not followed. Cookies are not stored. The timeout is 60 seconds.
4. When the upstream fails, the app gets status 502 with a JSON error.

Before a request reaches the list, DevHub removes the `Authorization`, `Cookie`, `Set-Cookie` and `Proxy-Authorization` headers and masks tokens and passwords in the URL, the bodies, the GraphQL variables and the errors.

### Rule editor

The Rules button shows the sets and their rules.

| Action | What it does |
|---|---|
| Set picker | Chooses the set to edit. It also becomes the set of the selected simulator. Its hint names the folder of the set files (`network.mocksFolder`, else `~/.devhub/mocks/<project folder name>`) |
| New mock set | Creates "New set" (a number is added when the name exists) |
| Rename… | Renames the set. The file name changes too |
| Duplicate | Copies the set as "<name> copy". Every rule keeps its fields, also the GraphQL operation name |
| Delete… | Asks inside the bar, then deletes the set file and its body files. The question names the folder of the sets |
| Add Rule | Adds `GET /v1/` → Respond 200 `{}` and opens it in the editor |
| Rule switch | Enables or disables a rule |
| Rule click, pencil | Opens or closes the editor of the rule |
| Trash | Asks inside the row, then deletes the rule |

A change goes to the running servers that use this set at once. No relaunch is needed for a rule change.

The editor fields:

| Field | Meaning |
|---|---|
| Method | ANY, GET, POST, PUT, PATCH, DELETE |
| Path | Must start with `/`. `*` matches one segment, `**` matches any number of segments |
| Query | `key=value` pairs that must be in the request query. A key without a value only has to be present |
| GraphQL | An operation name. `*` is allowed, for example `Get*`. Empty for REST |
| Action | **Respond** or **Patch real response** |
| Delay, ms | A whole number of milliseconds |
| Status, Content-Type, body | Respond only. The status must be 100 to 599. A JSON body must be valid JSON |
| Patch lines | Patch only. One change per line: `data.profile.vip = true` sets a value, `remove data.banner` removes a key. `[0]` selects an array item. A value is JSON; other text becomes a string |

The editor refuses typographic quotes (“ ”) next to JSON punctuation.

### Rule matching

`MockRuleMatcher` takes the first enabled rule where all of these match:

1. the method (an empty method matches all);
2. the path pattern;
3. the query pairs;
4. the GraphQL operation name, when the rule has one. A batch matches when one of its operations matches.

### GraphQL

`GraphQLParser` reads the operations of a request:

1. For `GET`, from the `query` parameter of the URL.
2. Otherwise, from the JSON body. A JSON array is a batch.
3. The name is `operationName`, else the name in the query document. The kind is `query`, `mutation` or `subscription`.

A response with an `errors` array counts as failed, even with status 200.

## Config

| Field | Effect here | Schema |
|---|---|---|
| `network.baseURLVariable` | The variable that gets `http://127.0.0.1:<port>`. Without it the mock server bar is hidden and the server cannot start | [§2](../extensions.md#2-projectjson) |
| `network.mocksFolder` | Where the set files live. A relative path starts at the project folder. Default `~/.devhub/mocks/<project folder name>` | [§2](../extensions.md#2-projectjson) |
| `launch.profiles[].upstream` | The real server the mock server forwards to | [§5](../extensions.md#5-launch-profiles) |
| `launch.profiles[].production` | The server refuses this profile | [§5](../extensions.md#5-launch-profiles) |
| `launch.profiles[].storage` | Helps to find the profile of the installed app | [§5](../extensions.md#5-launch-profiles) |
| `simulators.statusScript` | Its `state` line gives the host and profile of the app | [§6](../extensions.md#6-simulator-status-script) |
| `network.toolbar` placement | Config actions get a button under the filters, with the chosen simulator in `DEVHUB_SIMULATOR_UDID`. `refresh: ["network"]` reads the mock sets again | [§3](../extensions.md) |

The set file format is in [extensions §9](../extensions.md#9-mock-set-files).

1. Each set is one `<name>.json` file. Characters other than letters, digits, `-` and `_` in the name become `-`.
2. A response body longer than 1,024 bytes goes to a separate file in `<name>/bodies/` and the rule points to it with `bodyFile`.
3. DevHub reads the sets again when the tab opens, and when `network.mocksFolder` changes.

## Saved preferences

| Key | Value | Written by |
|---|---|---|
| `network.simulator` | UDID of the chosen simulator | `NetworkStore` |
| `network.filter` | `all`, `failed` or `slow` | `NetworkStore` |
| `network.mock.settings` | Per simulator: mode, set ID, and the upstream URL of the running server | `MockServerStore` |

The mock sets are files, not preferences.

## Limits

1. The list shows only the requests that pass through the DevHub mock server. Traffic that the app sends to other hosts is not shown.
2. Without `network.baseURLVariable` the server cannot redirect the app, and the mode, the set picker and the Rules button are hidden.
3. The app reads the server URL only at launch. A change of the mode or the set needs Apply & Relaunch.
4. A launch from Xcode or the home screen does not get the variable. The app status line warns about it.
5. WebSockets are not mocked or forwarded.
6. A production profile cannot use the mock server. This refusal was checked by tests only.
7. Copy as cURL has no request headers. Add the token by hand.
8. The list keeps 2,000 requests per simulator, in memory only.
