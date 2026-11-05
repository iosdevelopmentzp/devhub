# Device identity

Some apps identify a device or an account with an ID. DevHub can give each simulator its own ID for a launch. The app reads the ID from an environment variable. We call this the launch identity.

The feature appears only when `launch.identity` is set in `.devhub/project.json`.

Source: `Packages/DevHubKit/Sources/DevHubPresentation/Features/DeviceIdentity/`, `DevHubDomain/Policies/CleanInstallPolicy.swift`, `DevHubDomain/Values/LaunchPlan.swift`, `DevHubDomain/UseCases/LaunchInstalledAppUseCase.swift`, `DevHubData/Simulators/SimctlAppLaunchRepository.swift`.

Related pages: [Simulators](simulators.md), [Network](network.md).

## What it shows

The identity appears in four places.

1. **The identity summary** under a simulator row and under the target of the run bar. It shows only when the app is installed:
   - the profile tag of the app (teal; red for a `production: true` profile);
   - the alias and the current ID;
   - the user, when the status script reports one;
   - an orange `next: <ID>` tag when the next launch uses another ID;
   - a mock server tag, when the Network tab runs a server for this simulator ([Network](network.md));
   - "Launching…" while a launch runs.
2. **The ID controls** in the run bar and in the "Build & Run on…" picker: the ID field, **Saved**, **New**, **Own** and the alias field.
3. **The clean install note** under the ID controls. It says what the next launch does (see "Clean install rule" below).
4. **The identity panel** under a simulator row. The person button of the row opens it.

When the app is not installed on the target, the run bar shows "App not installed on this simulator".

### The identity panel

The panel has two parts.

**"Now on this simulator"** shows what the installed app uses now:

| Line | Source |
|---|---|
| Profile | The `profile` field of the status script `state` line, else the value at `storage` of a profile, else the profile of the last launch from DevHub. "no profile" when none is known |
| Host | The `host` field of the `state` line |
| ID | The `identity` field of the `state` line, else the ID of the last launch from DevHub. "own ID" when that launch set no ID. "unknown" before the first launch from DevHub |
| User | The `user` field of the `state` line |
| App | The `version` field of the `state` line, else `CFBundleShortVersionString` of the installed app |
| Hook tag | Green `<variable>` when the app binary contains `hookMarker`. Green `<variable> · ID kept` when it also contains `keptVariable`. Red `no <variable> hook` otherwise |
| Last launch | "last launch from DevHub <time>" |

When the app is not installed, the panel says so: Build & Run first.

**The lower part** sets what the next launch uses: the ID controls, the clean install note, and the launch buttons.

## Actions

### ID controls

| Control | What it does |
|---|---|
| ID field | The ID for the next launch on this simulator. Empty means the app's own ID |
| Saved | Picks an ID used before. "Forget" removes an ID and its alias from the list |
| New | Fills in a new random ID: `idPrefix` plus 8 hex characters, for example `devhub-3f9a1c2e` |
| Own | Empties the field: DevHub sets no ID |
| Alias | A name for the ID in the field. When the field is empty, the name belongs to the current ID of the app. DevHub shows the alias next to the ID |

DevHub adds an ID to the saved list when a build starts with it, or when you give it an alias.

### Launch buttons of the identity panel

These buttons launch the installed app. They do not build.

| Button | What it does |
|---|---|
| Launch | Launches the installed app with the profile of this simulator and the chosen ID. The title is "Reinstall & Launch" when the launch makes a clean install |
| Launch & Attach | The same launch with `--wait-for-debugger`, then attaches Xcode (see [Run & Attach](simulators.md#run--attach)). Needs the Accessibility permission |
| Refresh (arrow button) | Reads the installed app again |
| Close | Closes the panel |

The steps of a launch (`LaunchInstalledAppUseCase`):

1. `xcrun simctl boot <udid>` and `xcrun simctl bootstatus <udid>`.
2. Clean install, when needed (see below). DevHub keeps a copy of the installed app first, so it can install it again:
   - `xcrun simctl get_app_container <udid> <bundle ID> app`;
   - `ditto <installed app> ~/Library/Caches/DevHub/Apps/<udid>-<bundle ID>.app`;
   - `xcrun simctl terminate <udid> <bundle ID>` and `xcrun simctl uninstall <udid> <bundle ID>` (failures are ignored);
   - `xcrun simctl keychain <udid> reset`;
   - `xcrun simctl install <udid> <cached app>`. Without a cached copy, DevHub uses the last built app. Without both, the launch fails: "No app bundle to reinstall from".
3. The profile `defaults`, written as in [Install and launch](simulators.md#install-and-launch).
4. The mock server variable, when a server runs for this simulator.
5. The simulator window: Simulator.app, or Device Hub with Xcode 27 ([Simulator app](simulators.md#simulator-app)).
6. `xcrun simctl launch --terminate-running-process [--wait-for-debugger] <udid> <bundle ID> <arguments>`.

### What a launch sends to the app

Every launch from DevHub (Build & Run, Launch, Apply & Relaunch in the Network tab) builds one launch plan (`LaunchPlan`).

| Value | Content |
|---|---|
| Environment | The `env` of the profile, plus `<variable>=<ID>` when an ID is chosen, plus `<keptVariable>=<ID>` (an empty string when no ID is chosen) |
| Arguments | `launch.identity.args`, then the `args` of the profile |
| Defaults | The `defaults` of the profile |

The environment reaches the app as `SIMCTL_CHILD_<NAME>` variables of `xcrun simctl launch`.

After the launch, DevHub saves a launch record for this simulator: bundle ID, profile, ID, mock server URL and time. About 4 seconds later DevHub reads the installed app again. About 3 seconds later the status script runs again.

### Reading the installed app

DevHub reads the app for booted and favorite simulators, and for simulators with installed apps. It reads again after a launch, on a config change and when the panel opens.

1. Find the app: `xcrun simctl get_app_container <udid> <bundle ID> app`. When this fails, DevHub looks in `~/Library/Developer/CoreSimulator/Devices/<udid>/data/Containers/Bundle/Application`.
2. Read `CFBundleExecutable` and `CFBundleShortVersionString` from its `Info.plist`.
3. Look for the hook: `grep -q -a -F <marker> <file>` on the executable and on every `*.debug.dylib` in the app.
4. Read the stored profile: the first profile with `storage` gives the suite and key. DevHub reads `Library/Preferences/<suite>.plist` from the data container (or the group container for a `group.` suite).

### The bundle ID

The bundle ID of the panel and of a launch from it is the bundle ID of the last launch from DevHub on this simulator, when the project config knows it. Otherwise it is the effective bundle ID of the project (`xcode.bundleIDs`, `xcode.bundleID`, or the detected one).

Deep links, push, the "Uninstall" menu item and the process lookup of the Logs tab use the same bundle ID (`IdentityLookup.bundleID(for:)`).

## Clean install rule

A clean install deletes the app, resets the simulator keychain and installs the app again. The session of the app is lost.

A launch from DevHub makes a clean install when one of these is true:

1. The **Clean install** box of the run bar is on.
2. The profile has `cleanInstall: true`.
3. The clean install rule says so (`CleanInstallPolicy`).

The rule applies only when `launch.identity.cleanInstallOnChange` is `true` (the default) and the app is installed. The "actual ID" is the `identity` of the status script `state` line, else the ID of the last launch from DevHub.

| Chosen ID | Actual ID | Clean install |
|---|---|---|
| set | the same | no |
| set | different or unknown | yes |
| empty | unknown | no |
| empty | an ID that DevHub set, or one in the saved list | yes |
| empty | another ID (the app's own) | no |

The note under the ID controls says the result in words:

1. "The app on this simulator has another ID: the next launch deletes the app, resets the simulator keychain and installs it again."
2. "Clean install is on: …" when only the box is on.
3. "`launch.identity.cleanInstallOnChange` is off: the app is updated in place even when the ID changes."
4. "Same ID as now: the app is updated in place and the session stays."

## Config

| Field | Effect here | Schema |
|---|---|---|
| `launch.identity.variable` | The environment variable that holds the ID. Required: without `launch.identity` the feature is hidden | [§2](../extensions.md#2-projectjson) |
| `launch.identity.keptVariable` | A second variable with the same value; the "ID kept" tag | [§2](../extensions.md#2-projectjson) |
| `launch.identity.args` | Arguments added to every launch | [§2](../extensions.md#2-projectjson) |
| `launch.identity.idPrefix` | The start of a new ID. Default `devhub-` | [§2](../extensions.md#2-projectjson) |
| `launch.identity.cleanInstallOnChange` | Turns the clean install rule on or off. Default `true` | [§2](../extensions.md#2-projectjson) |
| `launch.identity.hookMarker` | The text DevHub searches for in the app binary. Default: the value of `variable` | [§2](../extensions.md#2-projectjson) |
| `launch.profiles[].storage` | Where the app saves its current profile | [§5](../extensions.md#5-launch-profiles) |
| `launch.profiles[].production` | The profile tag is red | [§5](../extensions.md#5-launch-profiles) |
| `simulators.statusScript` | Its `state` line gives the actual ID, profile, host, user and version | [§6](../extensions.md#6-simulator-status-script), [§7](../extensions.md#7-script-line-protocol) |

## Saved preferences

| Key | Value | Written by |
|---|---|---|
| `simulators.launchSettings` | Per simulator: the chosen ID, the last ID DevHub set, whether DevHub launched the app, and the last launch record (bundle ID, profile, ID, mock server URL, time) | `IdentityStore` |
| `devhub.savedDeviceIDs` | The list of saved IDs | `IdentityStore` |
| `devhub.deviceIDAliases` | Alias per ID | `IdentityStore` |

The old key `simulators.identity` is not read.

## Limits

1. Without `launch.identity` the identity panel, the ID controls and Launch & Attach in the row menu are hidden.
2. DevHub sees the real ID of the app only through the `state` line of the status script. Without it, DevHub knows only the ID of its own last launch.
3. With `xcode.bundleIDs` per scheme, the identity panel reads the app of the effective scheme until the first launch from DevHub on that simulator.
4. Launches from Xcode or the home screen do not get the ID, unless the app keeps it itself (`keptVariable`).
5. Only the first profile with `storage` is used to read the stored profile.
6. A clean install from the identity panel needs an installed app or a built app to copy from.
