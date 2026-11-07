# Simulators tab

The Simulators tab lists the iOS simulators of this Mac and holds the run bar. The run bar builds the project and launches the app on one simulator, the target.

Source: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Simulators/` and `Features/Build/`, `DevHubData/Simulators/`, `DevHubData/Build/`, `DevHubDomain/UseCases/BuildAndRunUseCase.swift`, `CommandRunUseCase.swift`, `AppInstallStep.swift`.

Related pages: [Device identity](device-identity.md), [Logs](logs.md), [Network](network.md).

## What it shows

The tab has three parts, from top to bottom.

1. **The run bar.** It shows:
   - the scheme picker and the configuration picker (`Debug`, `Release` and the configured one). A `kind: command` project shows its `build.command → run.command` line instead;
   - the button next to the scheme picker opens the scheme editor. It lists the schemes and targets from `xcodebuild -list -json` that are not in the picker yet; a click adds one. A text field adds any other name. The schemes added by you show under "Added by you" with a remove button. The list is saved per project. The picker finds only `.xcscheme` files, so a scheme that Xcode creates on the fly (a target without a shared scheme, a Swift package product) needs this editor or `xcode.schemes`;
   - the source badge: a gray "Main checkout · <branch>", or an orange "Worktree · <name>" or "Branch · <name>", so a build that does not come from the main checkout stands out; a click opens the menu with the main checkout, the worktrees and "Other Branch…";
   - the **Fast** box (incremental build) and the **Clean install** box;
   - an Xcode tag (`Xcode 26.1`) with the version of the Xcode that builds the project and runs `simctl` and `xed`. The hint names the app and where the choice comes from: Settings → Projects, `xcode.developerDir` in `.devhub/project.json`, or `xcode-select` ([Settings](settings.md));
   - the launch profile picker, when the project has `launch.profiles`. With 4 profiles or fewer it is a segmented control, with more it is a menu. A summary line shows the environment, the argument count, the defaults count and "clean install";
   - the target: name, device icon, runtime tag, the status script line, and the identity summary (see [Device identity](device-identity.md));
   - config actions with the `simulators.runBar` placement;
   - the device ID and alias controls and the clean install note, when `launch.identity` is set;
   - while a build runs: the step text and a progress bar;
   - after a build: a green "Launched on … · <time>" line or the red error, with **Show log**.
2. **The toolbar.** It shows the number of simulators and of devices ("7 simulators · 1 devices"), a "with apps" tag (simulators with installed apps) and **Remove Apps from All…**.
3. **The list.** A "Favorites" section comes first, in your own order: drag a favorite row onto another favorite row to move it there. A new favorite goes to the end. Then a "Devices" section with the paired iPhones and iPads (see "Physical devices" below), then one section per iOS runtime, newest runtime first. Each row shows:
   - a state dot (green booted, orange booting or shutting down, gray shut down);
   - the name, the runtime tag, a blue `target` tag on the target row, a star for a favorite;
   - the state and the number of installed apps, for example "Booted · 3 apps installed";
   - the status script line (see "Status script line" below);
   - the identity summary, when `launch.identity` is set and the app is installed.

The search field in the toolbar filters rows by simulator name, runtime and UDID.

The list comes from `xcrun simctl list devices available -j`. Only iOS runtimes are listed. The app count is the number of folders in `~/Library/Developer/CoreSimulator/Devices/<udid>/data/Containers/Bundle/Application`. The devices come from `xcrun devicectl list devices`; when that command fails (an old Xcode), the simulators still show and the failure is logged once.

### The target

The target is the simulator that Build & Run uses.

1. A click on a row makes it the target.
2. Without a saved target, the target is the first booted simulator, else the first simulator, else the first connected device.
3. Build & Run from a row also makes that row the target.

## Actions

An action below shows an operation card in the tray at the bottom of the tab: the steps with their state and time while it runs, and after a failure the failed step, the lines that explain it, Retry (when the action can run again), Copy Error and Full Output. See [Operations](output.md#operations).

### Simulator rows

Row buttons appear on hover. The overflow menu (`…`) holds the rest.

| Action | Where | What it does | Command |
|---|---|---|---|
| Boot | power button | Boots the simulator | `xcrun simctl boot <udid>` (exit code 149, "already booted", counts as success) |
| Shutdown | power button | Shuts the simulator down | `xcrun simctl shutdown <udid>` (exit code 149 counts as success) |
| Device ID and environment | person button | Opens the identity panel under the row. Only with `launch.identity` | see [Device identity](device-identity.md) |
| Deep link and push | paper plane button | Opens the messaging panel under the row | see "Deep links and push" below |
| Build & Run on this simulator | play button | Makes the row the target and starts Build & Run | see "Build & Run" below |
| Remove all installed apps | `xmark.app` button, and the menu | Removes every user app. Settings stay. A shut-down simulator boots first and shuts down after | `xcrun simctl listapps <udid>`, then `xcrun simctl uninstall <udid> <bundle ID>` per app with `ApplicationType` `User` |
| Open in Simulator, or Open in Device Hub | menu | Shows this simulator in the simulator app of the Xcode in use | see "Simulator app" below |
| Stream App Logs | menu, booted only | Opens the Logs tab and starts a stream for this simulator | see [Logs](logs.md) |
| App Data… | menu, booted only | Opens the app data panel under the row | see "App data" below |
| Add to Favorites, Remove from Favorites | menu | Moves the row to or from the Favorites section | none |
| Launch & Attach Xcode | menu, only with `launch.identity` and an installed app | Launches the installed app without a build and attaches Xcode | see [Device identity](device-identity.md) |
| Uninstall `<bundle ID>` | menu | Removes the app of the project. A shut-down simulator boots first and shuts down after | `xcrun simctl uninstall <udid> <bundle ID>` |
| Copy UDID | menu | Copies the UDID | none |
| Config actions | menu | Actions with the `simulators.row` placement. Their inputs and confirmation open under the row | the action's `run` |
| Erase Content and Settings… | menu | Asks for confirmation inside the row, then shuts down and erases the simulator | `xcrun simctl shutdown <udid>`, then `xcrun simctl erase <udid>` |
| Delete Simulator… | menu | Asks for confirmation inside the row (with the warning that the simulator, its apps and its data go away), then shuts down and deletes the simulator from this Mac. The list refreshes without it. Xcode → Devices and Simulators can create a new one | `xcrun simctl shutdown <udid>`, then `xcrun simctl delete <udid>` |

To boot a shut-down simulator for an uninstall, DevHub runs `xcrun simctl boot <udid>` and `xcrun simctl bootstatus <udid>`.

### Toolbar

| Action | What it does | Command |
|---|---|---|
| Remove Apps from All… | Asks for confirmation, then removes every user app from every simulator that has apps, one simulator at a time. A progress line shows the current simulator. **Stop** ends the loop after the current simulator | the same commands as "Remove all installed apps" |

### Build & Run

Build & Run starts from the run bar button (⌘R), the row play button, a quick action, or a "Build & Run on…" picker in a branch, worktree or pull request row. The picker lists booted simulators first, then favorites, then the rest. Its button says "Reinstall & Run" when the run will make a clean install.

For an Xcode project (`kind: xcode`), the steps are:

1. **Prepare the source.** For a branch without a checkout, DevHub creates a worktree first. When the worktree needs it, DevHub runs the bootstrap script of `git.worktrees`.
2. **Boot.** `xcrun simctl boot <udid>`.
3. **Clean.** Only when **Fast** is off: `xcodebuild -workspace <path> -scheme <scheme> -configuration <configuration> -destination id=<udid> clean`. A project without a workspace uses `-project <path>`.
4. **Build.** `xcodebuild <the same arguments> ONLY_ACTIVE_ARCH=YES build`. The working folder is the checkout of the source.
5. **Locate the app.** DevHub reads the `.app` path from the build output, else from `Build/Products/<configuration>-iphonesimulator` in DerivedData, else from `xcodebuild … -showBuildSettings -json`. The bundle ID comes from the `Info.plist` of that app.
6. **Install** (see "Install and launch" below).

For a `kind: command` project, the steps are:

1. Prepare the source and boot, as above.
2. Run `build.command`, then `run.command`, in the checkout. Each command gets the context variables of [extensions §3.4](../extensions.md#34-context-variables). A file without the executable bit runs through `/bin/zsh`.
3. A line `@devhub {"app": "<path>"}` names the app. A relative path starts at the checkout. Without this line, DevHub stops here: the commands launch the app by themselves.
4. With an app path, DevHub installs and launches it the same way as for an Xcode project.

A `@devhub {"progress": …}` line updates the step text. A `@devhub {"error": …}` line fails the run.

### Build errors and warnings

While `xcodebuild` runs, DevHub reads every `<file>:<line>:<column>: error: …` and `… warning: …` line, and every `error: …` line without a file. The run bar lists them under the result: a title such as "2 errors · 5 warnings", errors first, five lines with "Show all N". A click on a line opens the file at that line in the editor from Settings. A repeated line shows once; the list keeps at most 200 lines and is cleared when the next build starts. A `kind: command` project has no list: its scripts print their own output.

When the list has at least one error, "Fix with AI" next to the title writes the errors (and the warnings, marked as second) into a prompt file (`~/.devhub/prompts/fix-build-<scheme>.md`) and starts Claude Code or Copilot CLI in the terminal inside the build source (the main checkout or the chosen worktree), with the command from `ai.commands`.

### Install and launch

These steps are shared by both project kinds (`AppInstallStep`).

1. Wait for the boot: `xcrun simctl bootstatus <udid>`.
2. **Clean install**, when the **Clean install** box is on, the profile has `cleanInstall: true`, or the clean install rule says so ([Device identity](device-identity.md)):
   - `xcrun simctl uninstall <udid> <bundle ID>` (a failure is ignored);
   - `xcrun simctl keychain <udid> reset`.
3. **Install:** `xcrun simctl install <udid> <app path>`.
4. **Profile defaults**, when the profile has `defaults`. For each container:
   - `xcrun simctl get_app_container <udid> <bundle ID> data` (or the `group.…` suite name for an app group);
   - `xcrun simctl spawn <udid> defaults write <container>/Library/Preferences/<suite>.plist <key> -string|-bool|-integer|-float <value>`.
5. **Mock server.** When the Network tab runs a mock server for this simulator, DevHub moves it to the upstream of the profile and adds `network.baseURLVariable` to the environment ([Network](network.md)).
6. **Simulator window:** the simulator app of the Xcode in use, see "Simulator app" below.
7. **Launch:** `xcrun simctl launch --terminate-running-process <udid> <bundle ID> <arguments>`. The environment of the profile and of `launch.identity` goes to the app as `SIMCTL_CHILD_<NAME>` variables. The arguments are `launch.identity.args`, then the `args` of the profile.

On a physical device the steps are: clean install (`devicectl device uninstall app`, when the app is installed), `devicectl device install app`, the profile defaults, then `devicectl device process launch --terminate-existing` with the same environment and arguments. No boot, no keychain reset, no mock server. See "Physical devices".

### Physical devices

An iPhone or iPad that is paired with this Mac, in Developer Mode and reachable by cable or Wi-Fi shows in the "Devices" section: its name, its iOS version as the runtime tag, a `device` tag and "Connected" or "Not connected". `xcrun devicectl list devices` is the source; the row id is the hardware UDID. A device that is paired but switched off or away stays in the list as "Not connected".

What works on a device, through `xcrun devicectl`:

- **Target and Build & Run.** A click makes the device the target. The build runs `xcodebuild -destination id=<udid> -allowProvisioningUpdates` with the signing of the project (automatic signing with the team, Xcode logged in; DevHub manages no certificates). Then `devicectl device install app --device <udid> <App.app>` and `devicectl device process launch --device <udid> --terminate-existing --environment-variables <JSON> <bundle ID> <arguments>`. The app opens on the device.
- **Launch profiles and the device ID.** `env`, `args` and the ID go into the launch; `defaults` are written into `Library/Preferences/<suite>.plist` of the app on the device (`devicectl device copy from`, `defaults write` on the Mac, `devicectl device copy to`). A `group.` suite is read and written in the app data container too.
- **Clean install** removes the app (`devicectl device uninstall app`) and installs the last build again. The keychain of the device stays.
- **The identity panel** reads the installed version with `devicectl device info apps`, the stored profile from the copied preferences plist, and the identity hook from the last product that DevHub built on this Mac ([Device identity](device-identity.md)).
- **Uninstall**, **Favorites**, **Copy UDID**, config actions of the row (`DEVHUB_SIMULATOR_KIND=device`) and the status script (with empty container variables).

Not available on a device, and hidden in its row: boot and shutdown, erase, delete, remove all apps, logs, app data, QA settings, deep links, push and the mock server. Build & Run, Run & Attach and Launch & Attach on a device that is "Not connected" are disabled.

### Simulator app

Xcode 27 has no Simulator.app. Device Hub (`DeviceHub.app`, bundle ID `com.apple.dt.Devices`) shows the simulators instead, and `xcrun simctl` works as before. DevHub opens the app of the Xcode that the project uses (Settings → Projects, else `xcode-select -p`). Code: `SimctlSimulatorRepository.openInSimulatorApp`, `SimulatorAppLocation`.

| The Xcode has | DevHub runs |
|---|---|
| `<Xcode>/Contents/Developer/Applications/Simulator.app` (Xcode 26 and earlier) | `open <that path> --args -CurrentDeviceUDID <udid>` |
| `<Xcode>/Contents/Applications/DeviceHub.app` (Xcode 27) | `xcrun simctl boot <udid>` (exit code 149 counts as success), then `open devices://device/open?id=<udid>`. When the URL fails: `open -a <DeviceHub path>` |
| neither, or no developer folder | `open -a Simulator --args -CurrentDeviceUDID <udid>`. When that fails: the Device Hub steps, with `open -b com.apple.dt.Devices` as the last one |

- Device Hub shows no window for a simulator that is still shut down when the URL arrives, so DevHub boots it first.
- Apple does not document the `devices://` URL. The React Native CLI and the Expo CLI use it to show one device.
- The row menu says "Open in Simulator" or "Open in Device Hub". The Simulators tab reads the app on every refresh.
- Not checked on a Mac with Xcode 27 yet.

### Crash reports

After DevHub launches the app on a simulator (Build & Run, Run & Attach, Launch), it watches the folder of the macOS crash reports, `~/Library/Logs/DiagnosticReports`. It starts no process and no timer: one file system event source (one open folder) wakes DevHub when a file is added, and DevHub reads only the `.ips` files newer than the launch. A report counts when it is a crash (`bug_type` 309), comes from a simulator (`CoreSimulator/Devices/<UDID>` in the process path), has the bundle ID of the launched app, and is not older than 5 seconds before the launch. The watch stays on until DevHub quits.

A crash shows a red block in the run bar:

- "<app> crashed" and the time;
- the exception and signal, and the first frame of the app code with its file and line (`EXC_BREAKPOINT (SIGTRAP) · ProfileViewModel.load() at ProfileViewModel.swift:42`);
- the messages of the report (for example the Swift `Fatal error` line or the reason of an uncaught exception);
- Show Stack: the first 15 frames of the crashed thread, frames of the app in bold;
- Open Report: opens the `.ips` file in its app (Console);
- Fix with AI: writes the crash into `~/.devhub/prompts/fix-crash-<app>.md` and starts Claude Code or Copilot CLI in the terminal, inside the build source;
- a close button hides the block.

Each crash is also a red line in Recent with a click to the run bar, and a macOS notification of the kind "App crashes on a simulator" (its own switch in Settings).

### Run & Attach

Run & Attach (⇧⌘R) works only for an Xcode project.

1. DevHub checks the Accessibility permission. Without it, DevHub asks for it and stops.
2. DevHub builds and installs as above, then launches with `--wait-for-debugger`.
3. DevHub opens the project in Xcode (`open -a Xcode <container>`), selects the simulator as the run destination, and clicks **Debug → Attach to Process by PID or Name…** through `osascript`.
4. DevHub waits up to 25 seconds for the process to continue.

On a physical device, step 2 launches with `devicectl device process launch --start-stopped` and reads the process ID from its JSON. Step 3 selects the device as the run destination. Step 4 is a fixed wait of 5 seconds, because DevHub cannot read the state of a process on the device. Without a process ID from devicectl the run fails with a message. The device path is covered by tests only, not by a run on a real device.

Xcode's console stays empty for an attached process.

### Build only

Build (⌘B) runs the steps of Build & Run up to "Locate the app" and stops: no clean install, no install, no launch. The result line says "Built <scheme>, not launched", the app path is the last line of the build log (Show log), and the Recent list and a notification (panel closed) say "Built <scheme>". For a `kind: command` project it runs `build.command` only; an `app` line goes to the log and nothing is installed. `builtin.build` in `home.quickActions` puts the same action on Home, and the ⌘K palette lists it as "Build".

### Other run bar actions

| Action | What it does |
|---|---|
| Cancel | Stops the running build |
| Show log | Writes the build output (last 20,000 lines) to `DevHub-build.log` in the temporary folder and opens it |
| Refresh simulators | Reads the simulator list again |
| Source badge | Gray "Main checkout · <branch>", or orange "Worktree · <name>" or "Branch · <name>". A click opens the menu: the main checkout, a worktree, or "Other Branch…". A branch with a checkout uses that checkout; a branch without one gets a worktree on the next run |

A finished build posts a macOS notification while the panel is closed ([Settings](settings.md#notifications)).

### Deep links and push

The paper plane button opens a panel under the row.

| Action | What it does | Command |
|---|---|---|
| Open (deep link) | Opens the URL on the simulator, like a tap in Safari | `xcrun simctl openurl <udid> <url>` |
| URL scheme menu | Lists the URL schemes of the installed app and the last 15 links. "Forget" removes a link from the list | `xcrun simctl get_app_container <udid> <bundle ID> app`, then DevHub reads `CFBundleURLTypes` from the `Info.plist` |
| Templates | "Alert" (title = project name, body "Test notification from DevHub", sound, badge 1), "Silent (content-available)", and the last 10 payloads | none |
| Send Push | Sends the JSON payload to the app of the project. The payload must be valid JSON | DevHub writes the payload to a temporary `.apns` file, then runs `xcrun simctl push <udid> <bundle ID> <file>` |

Both buttons need a booted simulator. The URL scheme menu, Send Push and "Uninstall" take the bundle ID in this order ([Device identity](device-identity.md#the-bundle-id)):

1. the bundle ID of the last launch from DevHub on that simulator, when the project config knows it;
2. `xcode.bundleIDs` for the scheme;
3. `xcode.bundleID`;
4. the bundle ID of the Projects section in Settings.

### QA settings

The sliders button in a row opens a panel under the row. Every control works only on a booted simulator, and every change shows in Recent.

| Control | What it does | Command |
|---|---|---|
| Appearance: Light, Dark | The system appearance | `xcrun simctl ui <udid> appearance light\|dark` |
| Text size | Dynamic Type size, from "Extra small" to "Accessibility XXXL" | `xcrun simctl ui <udid> content_size <size>` |
| Status bar: Clean 9:41, Real | 9:41, full battery, full signal and Wi-Fi for screenshots; Real removes the override | `xcrun simctl status_bar <udid> override --time 9:41 …`, `status_bar <udid> clear` |
| Location: Set…, Clear | A city from a short list (Cupertino, New York, London, Berlin, Kyiv, Tokyo, Sydney) | `xcrun simctl location <udid> set <lat>,<lon>`, `location <udid> clear` |
| Language: Set… | Writes the language and the region of the simulator. Shut it down and boot it to see the change; the panel says so until the simulator shuts down | `xcrun simctl spawn <udid> defaults write -g AppleLanguages -array <code>`, `… AppleLocale -string <locale>` |
| Permission | Grant, Revoke or Reset one privacy service for the app of the row (the bundle ID of the last launch, else the project). `simctl` has no camera service | `xcrun simctl privacy <udid> grant\|revoke\|reset <service> <bundle ID>` |
| Frame: Add the device frame | One saved switch for screenshots, GIFs and converted videos. DevHub takes the frame from the Xcode on this Mac (the `chromeIdentifier` of the device type, then `/Library/Developer/DeviceKit/Chrome/<name>.devicechrome`) and draws it with the side buttons. A screenshot of a device without a frame stays plain, and Recent says why; a GIF or video of such a device fails with the reason | CoreGraphics and AVFoundation in DevHub |
| Screenshot: Save to Desktop | Saves `~/Desktop/<simulator> <date time>.png` (UTC). The file name then shows as a link that reveals it in Finder. With the frame switch on, the round screen corners are cut and the frame is drawn around the screenshot at the scale of the screen | `xcrun simctl io <udid> screenshot [--mask=alpha] <path>`, then CoreGraphics in DevHub |
| Video: Record, Stop | Records the screen of the simulator into `~/Desktop/<simulator> <date time>.mov` (UTC) until Stop. The line shows "Starting…", then the time since `simctl` printed "Recording started". The recording is an operation: the card above the panel and the footer show it with a stop button, and a failure keeps the reason. The file name then shows as a link that reveals it in Finder. Quitting DevHub stops every recording, so the files are written. The round corners of the screen are recorded black, like the bezel | `xcrun simctl io <udid> recordVideo --codec=h264 --mask=black --force <file>`, stopped with SIGINT |
| Video: Convert | Makes a GIF (320 px at 10 fps, 480 px or 640 px at 15 fps) or a smaller MP4 (720p H.264, 1080p HEVC) from the last recording, or from a `.mov`, `.mp4` or `.m4v` file that you choose. The result goes next to the source with a free name (`<name>.gif`, `<name> 720p.mp4`, `<name> 2.gif`, `<name> framed.gif` with the frame switch on) and shows as a link that reveals it in Finder. The work is an operation with a progress bar for a GIF and a stop button. A GIF keeps at most 600 frames: a long video gets fewer frames per second. A GIF is never wider than the video. A GIF has one frame for each change of the screen: a still screen becomes one long frame. With the frame switch on, a GIF is as wide as the chosen width with the frame, and an MP4 keeps the long side of its preset | AVFoundation and ImageIO in DevHub (`AVAssetReader` for the frame times, `AVAssetImageGenerator`, `CGImageDestination`, `AVAssetExportSession` with a video composition for the frame), no process |

### App data

"App Data…" in the row menu opens a panel under the row. It needs a booted simulator: DevHub reads the defaults through the running simulator. The app is the one of the row (the bundle ID of the last launch, else the project). The panel shows:

1. The data container path (click to copy) and a button that shows it in Finder.
2. **Folders**: Documents, Library/Application Support, Library/Caches, Library/Preferences and tmp with their size, then every app group container of the app. Each row opens in Finder.
3. **Databases**: the `.sqlite`, `.sqlite3`, `.db`, `.store` and `.realm` files of the data container and the group containers, with their size (40 at most).
4. **User defaults**, one section for the app and one for each app group. Each key shows its type and value. A filter field narrows the keys by key or value; a section shows 60 keys at most. A string, number or boolean can be edited (pencil), a boolean can be switched in one click, and every key can be deleted (inline confirmation). "Add Key" adds a key of type string, int, float or bool. A date, data, array or dictionary value is read only.
5. **Reset App Data…** with an inline confirmation: it stops the app, deletes its defaults and the contents of Documents, Library and tmp. A switch also clears the app group containers. Keychain items stay.

Config actions with the `simulators.appData` placement are buttons under the panel header, with their inputs, confirmation and result under the buttons. A script gets the simulator of the row, the app of the panel in `DEVHUB_BUNDLE_ID`, the containers in `DEVHUB_DATA_CONTAINER` and `DEVHUB_GROUP_CONTAINERS`, and `DEVHUB_SIMULATOR_STATE`. The panel reads the data again when the action ends, also after a failure. The schema and an example script are in `docs/extensions.md` (sections 3.3 and 3.4).

Every change runs as an operation: the card under the panel header shows the commands, and a failure keeps the reason. After a change the panel reads the data again. A running app reads a changed key after a relaunch.

| Step | Command |
|---|---|
| Data container | `xcrun simctl get_app_container <udid> <bundle ID> data` |
| App group containers | `xcrun simctl get_app_container <udid> <bundle ID> groups` |
| Read a suite | `xcrun simctl spawn <udid> defaults export <container>/Library/Preferences/<suite>.plist -` |
| Write a key | `xcrun simctl spawn <udid> defaults write <plist> <key> -string\|-integer\|-float\|-bool <value>` |
| Delete a key | `xcrun simctl spawn <udid> defaults delete <plist> <key>` |
| Reset | `xcrun simctl terminate <udid> <bundle ID>`, `xcrun simctl spawn <udid> defaults delete <plist>` per suite (exit code 1, "not found", counts as success), then DevHub removes the files |

DevHub writes the defaults through `defaults` inside the simulator, so the simulator's `cfprefsd` keeps the same values as the file. Folder sizes and the database list are read from the disk without a process.

### Status script line

When `simulators.statusScript` is set, DevHub runs the script for each simulator that is booted, a favorite or the target.

1. The script runs again 3 seconds after each Build & Run or launch, and on a refresh or a config change.
2. The script gets the context variables of [extensions §3.4](../extensions.md#34-context-variables). `DEVHUB_SIMULATOR_UDID` and `DEVHUB_SIMULATOR_NAME` are the ones of the row. `DEVHUB_CHECKOUT_PATH` is the project folder and `DEVHUB_BRANCH` is empty.
3. The row shows the last `view` line (`keyValues` as `Key: value · Key: value`, or `text`), else the last plain line.
4. A `state` line goes to the identity panel ([Device identity](device-identity.md)).
5. The script must end within 5 seconds. A slower script shows "status timed out".
6. A non-zero exit code shows the last line in red.
7. A missing file shows "Status script not found: <path>".

The same line also shows under the target in the run bar.

## Config

| Field | Effect here | Schema |
|---|---|---|
| `kind` | `xcode` builds with `xcodebuild`; `command` runs `build.command` and `run.command` | [§2](../extensions.md#2-projectjson) |
| `xcode.container` | The workspace or project for `xcodebuild`, the scheme list and the project that Run & Attach opens in Xcode | [§2](../extensions.md#2-projectjson) |
| `xcode.scheme`, `xcode.schemes` | The default scheme and the schemes in the picker | [§2](../extensions.md#2-projectjson) |
| `xcode.configuration` | The default configuration | [§2](../extensions.md#2-projectjson) |
| `xcode.bundleID`, `xcode.bundleIDs` | The bundle ID for the status script (`DEVHUB_BUNDLE_ID`), the identity panel, deep links, push and "Uninstall" | [§2](../extensions.md#2-projectjson) |
| `build.command`, `run.command` | The commands of a `kind: command` project | [§2](../extensions.md#2-projectjson) |
| `git.worktrees.*` | Where a worktree for a branch goes, and its bootstrap | [§2](../extensions.md#2-projectjson) |
| `launch.profiles[]` | The profile picker, `env`, `args`, `defaults`, `cleanInstall` | [§5](../extensions.md#5-launch-profiles) |
| `launch.identity.*` | The ID controls in the run bar and the identity panel | [Device identity](device-identity.md) |
| `network.baseURLVariable` | The mock server URL in the launch environment | [Network](network.md) |
| `simulators.statusScript` | The status script line | [§6](../extensions.md#6-simulator-status-script) |
| actions with `simulators.runBar`, `simulators.row` | Buttons in the run bar and items in the row menu | [§3.3](../extensions.md#33-placements) |

## Saved preferences

All keys live in the standard `UserDefaults` of the app (`KeyValueStore`).

| Key | Value | Written by |
|---|---|---|
| `simulators.target` | UDID of the target simulator | `BuildStore` |
| `simulators.runOptions` | Per simulator: scheme, configuration, Fast, Clean install, source, profile ID | `BuildStore` |
| `build.manualSchemes.<project id>` | The schemes added in the scheme editor | `BuildStore` |
| `simulators.favorites` | UDIDs of the favorite simulators, in the order of the Favorites section | `SimulatorsStore` |
| `messaging.urls` | The last 15 deep links | `MessagingStore` |
| `messaging.payloads` | The last 10 push payloads | `MessagingStore` |

The run options belong to the simulator. A click on another row loads the scheme, configuration, boxes, source and profile of that simulator.

## Limits

1. Only iOS simulators and paired iPhones and iPads are listed. watchOS, tvOS and visionOS are not shown.
2. `xcrun simctl boot` on a booted simulator shows a red row in the Output panel (exit code 149). The run goes on.
3. Run & Attach is off for `kind: command` projects.
4. Run & Attach needs the Accessibility permission. It clicks Xcode menus by name, so a changed Xcode menu breaks it.
5. Launch & Attach in a row needs `launch.identity`. Without it DevHub does not read whether the app is installed.
6. Profile values (`env`, `args`, `defaults`) reach the app only on a launch from DevHub. A launch from Xcode or the home screen does not get them.
7. The status script runs only for booted, favorite and target simulators.
8. The build log keeps the last 20,000 lines of one run.
9. The profile picker of the run bar does not mark a `production` profile in red. Only the profile tag of the identity panel is red, and the mock server refuses such a profile.
10. The app data panel needs a booted simulator, and a running app reads a changed key only after a relaunch.
11. A device without Developer Mode shows as connected; the install fails with the message of `devicectl`. A device build needs Xcode logged in to the team account for `-allowProvisioningUpdates`. The device must be unlocked for the launch.
12. On a device the identity hook is read from the last product DevHub built on this Mac, so a build installed by Xcode shows "no … hook" until DevHub builds once.
