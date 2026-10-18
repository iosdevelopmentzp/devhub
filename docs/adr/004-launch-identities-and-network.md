# ADR 004. Launch identities and the network mock server

Date: 2026-10-18. Status: accepted. Milestone: M6 of ADR 001. GraphQL support in the Network tab came in M7.

## Context

The main DevHub had a device identity panel and a Network tab for one app only:

- one identity preset, matched by the bundle ID of that app;
- three fixed environment variable names and one fixed plist key;
- fixed environment names (`qa`, `dev`, `prod`);
- a reader of the app's own session log file. DevHub read the device ID, the user and the server host from that log, and the Network tab listed the requests from the same log.

A generic app cannot know these names or that log format. ADR 001 sections 7.6, 7.7 and Appendix A planned to replace them with config. The owner approved the config keys on 2026-10-18 (STATUS decision 27).

Three terms in this ADR:

| Term | Meaning |
|---|---|
| identity | a value that the app reads from an environment variable at launch, for example a device ID or a test account ID |
| launch profile | a named set of environment variables, arguments and defaults for one server environment, for example "Staging" |
| upstream | the real server behind the DevHub mock server; the mock server forwards requests to it |

## Decision

### 1. Config decides, Domain holds the rules

The config keys are in `docs/extensions.md`. The Domain models are in `DevHubDomain/Models/Config/` and are `Codable` (STATUS decision 15).

| Key | Model | Effect |
|---|---|---|
| `launch.profiles[]` | `LaunchProfile` | `env`, `args`, `defaults`, `cleanInstall`, `storage`, `upstream`, `production` |
| `launch.identity` | `LaunchIdentityConfig` | `variable`, `keptVariable`, `args`, `idPrefix` (default `devhub-`), `cleanInstallOnChange` (default `true`), `hookMarker` (default: the value of `variable`) |
| `network.baseURLVariable` | `NetworkConfig` | the environment variable that gets the URL of the mock server |
| `network.mocksFolder` | `NetworkConfig` | the folder of the mock sets |
| `simulators.statusScript` | `SimulatorsConfig` | the status script; it may print the `state` directive |

Without `launch.identity` the identity panel is hidden. Without `network.baseURLVariable` the mock server bar is hidden.

A new identity is `idPrefix` plus the first 8 characters of a UUID in lower case (`LaunchIdentityConfig.newIdentity(uuid:)`), for example `devhub-3f9a1c2e`.

### 2. A launch is a plan, not stored state

`LaunchPlan` (`DevHubDomain/Values/`) joins the profile, `launch.identity`, the chosen identity and `network.baseURLVariable` (STATUS decision 28).

| Plan property | Value |
|---|---|
| `environment` | `profile.env`, then `variable` = the identity (only when an identity is chosen), then `keptVariable` = the identity or an empty string |
| `arguments` | `launch.identity.args` first, then `profile.args` |
| `defaults` | `profile.defaults` |
| `record(bundleID:baseURL:date:)` | the `LaunchRecord` of this launch |

`LaunchRecord` holds the bundle ID, the profile ID, the identity, the mock server URL (or nil) and the date. `IdentityStore` saves the last record per simulator in `SimulatorLaunchSettings.lastLaunch`, under the key `simulators.launchSettings`. The old key `simulators.identity` is not migrated.

### 3. One launch path for three buttons

Every launch goes through `SimulatorRepository.launch` with the environment and the arguments of the plan. The Data layer adds `SIMCTL_CHILD_` before every environment key.

| Button | Code | Steps |
|---|---|---|
| Build & Run | `AppInstallStep` (inside `BuildAndRunUseCase`) | clean install when needed, install, write defaults, mock preparation, open Simulator.app, launch, yield `.launched(record)` |
| Launch (installed app) | `LaunchInstalledAppUseCase`, called by `IdentityStore` | boot, clean install when needed, write defaults, mock preparation, open Simulator.app, launch, attach Xcode when asked |
| Apply & Relaunch (Network tab) | `RelaunchWithMocksUseCase`, called by `MockServerStore` | start, change or stop the mock server, write defaults, open Simulator.app, launch |

After each launch the store posts `AppEvent.buildFinished(simulatorID:launch:)` or `AppEvent.appLaunched(simulatorID:launch:)` with the record. `IdentityStore` saves the record, sets `appliedIdentity` and `hasApplied`, and reads the installed app again after 4 seconds. `SimulatorStatusStore` runs the status script again after 3 seconds.

`MockLaunchPreparation` runs in Build & Run and in Launch. When a mock server runs for that simulator, it puts the server URL into `network.baseURLVariable` and moves the server to the upstream of the chosen profile. When the profile has no upstream or is a production profile, it stops the server and writes the reason to the Output panel.

### 4. Three sources of facts about the app

| Source | Type | Where it comes from |
|---|---|---|
| the installed app | `InstalledApp` | `SimctlAppLaunchRepository.inspect`: the version from `Info.plist`; `hasIdentityHook` when `grep` finds the hook marker in the executable or a `*.debug.dylib`; `keepsIdentity` when it finds `keptVariable`; `storedProfileID` from the `storage` plist of the first profile that has `storage` |
| the app's own report | `AppStateReport` | the `state` directive of the status script (section "The `state` directive" below) |
| the last launch from DevHub | `LaunchRecord` | saved by `IdentityStore` after each launch |

The report has the highest priority. The identity panel reads the profile from `report.profile`, then `storedProfileID`, then `lastLaunch.profileID`. The actual identity is `report.identity`, then the identity that DevHub set last (`SimulatorLaunchSettings.actualIdentity`).

`IdentityStore` also saves the list of used identities (`devhub.savedDeviceIDs`) and their aliases (`devhub.deviceIDAliases`).

### 5. The clean install rule

`CleanInstallPolicy.needsCleanInstall` (STATUS decision 29). A clean install deletes the app, resets the simulator keychain and installs the app again.

| Case | Result |
|---|---|
| no `launch.identity`, `cleanInstallOnChange: false`, or the app is not installed | no clean install |
| an identity is chosen | clean install when the actual identity differs from the chosen one |
| no identity is chosen, and the actual identity is one that DevHub set or saved | clean install |
| no identity is chosen, and the actual identity is the app's own | no clean install |
| no identity is chosen, and the actual identity is unknown | no clean install |

A profile with `cleanInstall: true` and the "Clean install" switch of the run bar force a clean install in every case. Why the "app's own" row: a reinstall on every Build & Run would log the user out each time.

### 6. The bundle ID of the identity panel and the mock server

`IdentityStore.bundleID(for:)` uses the bundle ID of the last launch on that simulator when the project config knows that bundle ID. Otherwise it uses the effective bundle ID of the project (STATUS decision 30). Why: `IdentityStore` cannot read the scheme of the run bar, but the last launch records what Build & Run really installed.

The Simulators tab and the Logs tab read the same bundle ID through the `IdentityLookup` protocol: the URL scheme menu, Send Push, the "Uninstall" menu item and the process lookup of a log stream.

### 7. The mock server

The server lives in `DevHubData/Network/MockServer/`. This folder is the only place that may import Network.framework.

1. `NWMockServerRepository` is an actor with one `LocalMockServer` per simulator UDID.
2. A server is an `NWListener` on `127.0.0.1` that accepts only local connections.
3. The port is stable per simulator: `MockServerPortPolicy.port(for:)` gives a port from 49152 to 59151, from a hash of the UDID. When that port is taken, the server uses any free port.
4. A second `start` for the same simulator keeps the port and changes the upstream, the rules and the callback. `retarget` changes only the upstream. `update(udid:rules:)` changes only the rules.
5. One request per connection. `HTTPRequestParser` reads the request line, the headers and a body of up to 32 MB. A chunked request body gets status 501.
6. `MockExchangeHandler` handles a request:
   - a WebSocket upgrade gets status 501 ("WebSocket not mocked yet");
   - else `MockRuleMatcher` picks the first enabled rule;
   - a `respond` rule answers without the network;
   - a `patch` rule forwards the request, waits for the delay, then changes the JSON body with `JSONPatcher`;
   - no rule: the request goes to the upstream; an upstream failure becomes status 502.
7. Every exchange becomes a `NetworkRequest` and passes through `NetworkRequestRedactor` before the Network tab gets it. Nothing is saved to disk.
8. `MockServerStore` saves the mode, the set and the upstream per simulator (`network.mock.settings`). At app start, `restoreServers()` starts the saved servers again, so an app that DevHub launched earlier keeps working. It skips a production upstream, and it does nothing without `network.baseURLVariable`.
9. A project change stops every server.

### 8. The upstream comes from the launch profile

`MockUpstreamPolicy.upstream(for:)` returns the upstream URL or throws a `MockServerError`:

| Profile | Result |
|---|---|
| no profile | `noProfile` |
| `production: true` | `productionRefused(profile:)` |
| no `upstream`, or not an `http` or `https` URL with a host | `noUpstream(profile:)` |
| else | the URL |

`RelaunchWithMocksUseCase` also throws `disabled` when `network.baseURLVariable` is empty, and `noSetChosen` in Mock mode without a set. The error texts name the config key to fix.

Apply & Relaunch takes the profile in this order: `report.profile`, then `storedProfileID`, then the profile of the run bar. It uses the actual identity, not the chosen one, so a relaunch does not change the identity.

### 9. Rules

`MockRuleMatcher` (Domain) checks four things. All of them must match.

| Field | Match |
|---|---|
| `method` | case-insensitive; empty matches every method |
| `pathPattern` | per path segment; `*` inside a segment matches any text; `**` matches zero or more segments; the query part of the path is ignored |
| `query` | every `key` or `key=value` pair of the rule must be in the request query; values are percent-decoded |
| `operationName` | one of the GraphQL operation names of the request; `*` works as in a segment; empty matches every request |

The first enabled rule that matches wins.

### 10. GraphQL

`GraphQLParser` (Domain) reads the request and the response of every exchange:

1. A `POST` body is one JSON object or a batch (a JSON array). A `GET` request uses the `query`, `operationName` and `variables` query items.
2. The operation name is `operationName`, else the name after `query`, `mutation` or `subscription` in the document. A document that starts with `{` is an anonymous query.
3. A persisted query (no `query` text, but `operationName` and `extensions`) counts as a query.
4. `errors[].message` of the response become the errors of the exchange. An exchange with GraphQL errors counts as a failure, even with status 200.

The rule matcher reads the operation names from the request before the answer exists.

### 11. Where mock sets live

`MockSetLocationPolicy.location(network:projectPath:)` returns a `MockSetLocation`:

| `network.mocksFolder` | Folder |
|---|---|
| not set or empty | `~/.devhub/mocks/<project folder name>` (`.defaultFolder`; the name passes through `MockRouteName.stem`) |
| an absolute path or a path with `~` | that path |
| a relative path | the path inside the project folder |

`FileMockSetRepository` saves each set as `<set name>.json`. A response body over 1 KB goes to a file in `<set>/bodies/`. A change of the folder reloads the sets.

### 12. The app status line

`MockServerBarMapper.appStatus` tells whether the app really talks to the server. It checks the cases in this order:

| Case | Text | Tint |
|---|---|---|
| the app is not installed | "App not installed on this simulator" | secondary |
| no launch record | "Launched outside DevHub: traffic may bypass the server" | orange |
| the record has another base URL | "App points to an old DevHub server (…): relaunch" | orange |
| `report.host` is not `127.0.0.1` | "App reports … : launched without DevHub" | orange |
| the profile of the app and the profile of the upstream differ | "App is on …, the server forwards to …: relaunch" | orange |
| else | "App goes through DevHub (…)" | green |

The hint of the green line says "as of the last launch from DevHub". DevHub does not see a launch from Xcode, so the line can be out of date until the status script reports a host. The identity panel shows the same facts as a short tag (`IdentityPanelMapper.mockTag`).

### 13. Network empty states

`NetworkEmptyStateMapper` chooses one state when the list is empty:

| Case | Title |
|---|---|
| no `network.baseURLVariable` | "Network mocks are off for this project" |
| no booted simulator | "No simulator booted" |
| the server is off for this simulator | "Mock server is off" |
| the server runs, no requests yet | "Waiting for requests…" |
| a filter hides every request | "No … requests" |

## The `state` directive

The status script can print one line that tells DevHub what the app reports about itself:

```text
@devhub {"state": {"identity": "devhub-3f9a1c2e", "profile": "staging", "host": "api.staging.example.com", "user": "qa-12", "version": "2.4.0"}}
```

| Field | Used by |
|---|---|
| `identity` | the clean install rule, the "now on this simulator" summary, the alias of the current ID |
| `profile` | the profile tag of the identity panel, the profile of Apply & Relaunch; matched to a profile by `id`, then by `title` (case-insensitive) |
| `host` | the app status line and the mock tag; any host other than `127.0.0.1` means that the app does not use the mock server |
| `user` | the identity panel |
| `version` | the identity panel; without it DevHub shows the version from `Info.plist` |

Rules:

1. Only `simulators.statusScript` reads `state`. In other scripts DevHub ignores it.
2. Every field is optional. An empty string counts as a missing field. Other keys are ignored.
3. The same JSON object may also hold `view`, for example `{"state": {…}, "view": {"keyValues": […]}}`.
4. When the script prints more than one `state` line, the last one wins.
5. When the script fails, ends with a non-zero exit code or runs longer than 5 seconds, the report is empty.
6. The script runs for booted and favourite simulators and for the target of the run bar. It runs again 3 seconds after each launch, and after a config change, a project change or a simulator refresh.
7. The script gets the same context variables as a config action, for example `DEVHUB_SIMULATOR_UDID` and `DEVHUB_BUNDLE_ID`. It runs in the project folder.
8. `SimulatorStatusStore` keeps the report per simulator and posts `AppEvent.appStateReported(simulatorID:report:)`. `IdentityStore` keeps a copy for the identity panel.

The example script `docs/examples/devhub/scripts/sim-status.sh` reads the data container with `xcrun simctl get_app_container` and prints a `state` line and a `view` line.

## Changes from the ADR 001 plan

The code differs from ADR 001 sections 5.2, 7.6, 7.7 and Appendix A in these places:

| Plan | Code |
|---|---|
| a port `SimulatorStatusRepository` with `ScriptSimulatorStatusRepository`, `StatusScriptRunner` and `AppStateDirectiveParser`; a `simulatorStatus` field in `Ports` | `ReadSimulatorStatusUseCase` runs the script over the existing ports `ScriptRunning` and `ToolLocating`. `ScriptDirectiveParser` reads `state` like every other directive; `SimulatorStatusParser.state(_:)` takes the last one. `Ports` has no new field |
| `ReadInstalledAppUseCase` and a `readInstalledApp` field in `UseCases` | `IdentityStore` calls `AppLaunchRepository.inspect` directly |
| `AppLaunchRepository` with `applyProfile` and `launch` | `AppLaunchRepository` has only `inspect` and `cleanInstall`. Defaults go through `SimulatorRepository.writeDefaults`; every launch goes through `SimulatorRepository.launch` |
| `InstalledApp` holds `report` and `keyValues` | the report is separate: `SimulatorStatusStore` reads it and posts `appStateReported` |
| `AppStateReport` has `readAt` | no `readAt` |
| `LaunchPlan` has `bundleID` | the bundle ID is passed next to the plan; `LaunchRecord` has `bundleID` (STATUS decision 30) |
| `SimulatorLaunchSettings.desiredProfileID` | the profile per simulator stays in the run options of `BuildStore` |
| the order `profile.args`, then `identity.args` | `identity.args`, then `profile.args` |
| clean install when `actual != desired` | the extra case "no identity chosen" (STATUS decision 29) |
| `production: true` shows a red tint and asks before launch | the profile tag of the identity panel is red, and the mock server refuses the profile. Nothing asks before a launch, and the run bar picker has no red tint |
| `MockRelaunchRequest` uses `storedProfileID ?? desiredProfileID` | `report.profile`, then `storedProfileID`, then the run bar profile |
| `UpstreamResolver` becomes `UpstreamPolicy(profiles:)` | `MockUpstreamPolicy`, an enum with `upstream(for:)` and `profile(ofHost:in:)` |
| `MockSetRepository` methods take `folder: URL` | they take `MockSetLocation`; `MockSetLocationPolicy` resolves the config value |
| three empty states in the Network tab | five (section 13), with "mocks are off" first |
| the status script gets `DEVHUB_APP_CONTAINER` and `DEVHUB_DATA_CONTAINER`; actions get `DEVHUB_PROFILE` and `DEVHUB_HOST` | none of these variables exist. The script asks `simctl` for the container itself |
| `simulators.deepLinks` | dropped; schemes come from the installed app (STATUS decision 24) |
| the `network.toolbar` placement | not in the schema (STATUS known gaps) |
| this ADR as `docs/adr/003-launch-identities-and-network.md` (Appendix A.6 step 5) | number 003 went to the code host protocol; this ADR is 004 |

## Consequences

- A project without `launch.identity` and `network.baseURLVariable` sees no identity panel and no mock server bar. Build & Run still uses its profiles.
- Any app can use the identity panel: it needs one environment variable and, for the best result, a status script that prints `state`.
- The Network tab shows only the traffic that passes through the mock server. An app launched from Xcode or the home screen does not use the server.
- The session log reader, the identity presets and their tests are deleted.
- Tests: policies (`CleanInstallPolicy`, `MockUpstreamPolicy`, `MockRuleMatcher`, `GraphQLParser`, `MockSetLocationPolicy`, `SimulatorStatusParser`), use cases over spies, mappers per branch, and `MockServerIntegrationTests` over real sockets.

## Known gaps

1. DevHub cannot see a launch from Xcode after a launch from DevHub. The status line says "as of the last launch from DevHub". A `host` in the `state` report corrects it.
2. Without `identity` in the `state` report, the clean install rule uses the identity that DevHub set last. A build that starts with an identity of its own is not seen. `cleanInstallOnChange: false` turns the rule off.
3. The production refusal was checked by tests only, not on a running app.
4. With `xcode.bundleIDs` per scheme, the identity panel reads the app of the effective scheme until the first launch from DevHub on that simulator.
5. Launch & Attach in a simulator row needs `launch.identity`: without it DevHub does not read whether the app is installed.
6. WebSocket upgrades and chunked request bodies get status 501.
7. Only the first profile with `storage` is read for `storedProfileID`.
