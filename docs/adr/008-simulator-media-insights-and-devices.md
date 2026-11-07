# ADR 008. Simulator media, build insights, snapshots and real devices

Date: 2026-11-01. Status: accepted, in progress (see the plan and the step log).

This page is the brief for the implementation. The next session reads it first, then the files it names, then goes on with the first open step of the plan.

## Context

The owner compared DevHub with RocketSim, a paid Mac app that adds tools to the Xcode simulator, and chose these items (2026-11-01):

1. support for Xcode 27, which replaces Simulator.app with Device Hub;
2. GIF and compressed video from a simulator recording;
3. device frames around screenshots and recordings;
4. a network monitor;
5. build insights;
6. snapshots of the app state, with the keychain if possible;
7. real devices.

Facts checked on this Mac (Xcode 26.6, 2026-11-01):

- `simctl io recordVideo` writes the file only after SIGINT. `ShellRunner` stops a process with SIGTERM (`process.terminate()`), so DevHub has no recording yet (simulators page, QA settings).
- Xcode keeps device frames in `/Library/Developer/DeviceKit/Chrome/<name>.devicechrome/Contents/Resources/`: `chrome.json` and PDF parts (corners, edges, screen, buttons). A device type names its frame in `profile.plist` (`chromeIdentifier`, for example `com.apple.dt.devicekit.chrome.phone11` for iPhone 17 Pro).
- `DerivedData/<project>/Logs/Build/LogStoreManifest.plist` lists the builds and tests of Xcode and of `xcodebuild`: `title`, `schemeIdentifier-schemeName`, `timeStartedRecording`, `timeStoppedRecording`, `primaryObservable.highLevelStatus` (`S`, `W`, `E`), the error and warning counts, `uniqueIdentifier`.
- The simulator keychain is one SQLite database for all apps: `<device>/data/Library/Keychains/keychain-2-debug.db` with `-wal` and `-shm`. One device data folder was 6.3 GB.
- `simctl install_app_data <device> <xcappdata>` replaces the data container of an app and stops the app first.
- `xcrun devicectl list devices` sees a paired iPhone. `devicectl device copy from --domain-type appDataContainer` copies the data of an app from a device. `devicectl` has no screenshot command.
- In Xcode 27, `DeviceHub.app` (`com.apple.dt.Devices`) in `Xcode.app/Contents/Applications/` replaces `Simulator.app`, which Xcode 26 keeps in `Xcode.app/Contents/Developer/Applications/`. `simctl` stays, and `devicectl` also manages simulators. Tools that run `open -a Simulator` fail on a Mac with only Xcode 27 ("Unable to find application named 'Simulator'"). DevHub ran it in `SimctlSimulatorRepository.openInSimulatorApp` and in the example config (`list-devices` view).
- Found on the web (2026-11-05), not checked here: Device Hub registers the `devices://` URL scheme, and `open devices://device/open?id=<udid>` shows that device (the React Native CLI and the Expo CLI use it). Device Hub shows no window for a device that starts to boot after the URL, so the device must be booted first. Device Hub ignores `-CurrentDeviceUDID` and `-DeviceSetPath`.

## Decisions

### D1. Xcode 27 and Device Hub

1. DevHub opens the simulator app of the Xcode in use: `<developer dir>/Applications/Simulator.app` or `<developer dir>/../Applications/DeviceHub.app`, the one that exists (Simulator.app first). Device Hub gets `simctl boot`, then `devices://device/open?id=<udid>`, then `open -a <path>` when the URL fails. The developer dir is the project's `xcode.developerDir`, else `xcode-select -p`. The menu item says "Open in Simulator" or "Open in Device Hub". The example config stops using `open -a Simulator`.
2. Check on Xcode 27: the simulator list, boot, install, launch, logs, app data, QA settings, and whether Device Hub takes `-CurrentDeviceUDID`.
3. The owner installs Xcode 27 next to Xcode 26 (for example `/Applications/Xcode-27.app`) and chooses it for one project in Settings → Projects. The system Xcode stays 26. The first start of Xcode 27 installs its simulator service (CoreSimulator) for the whole Mac, and Xcode 26 then uses that service too.

### D2. Video recording (needed by D3 and D4)

1. `ShellRunner` gets a stop with SIGINT (`Process.interrupt()`). The default stop stays SIGTERM.
2. QA settings of a row: "Record" and "Stop" with a time counter. `xcrun simctl io <udid> recordVideo --codec=h264 --force <file>`. The file goes to the screenshot folder with the same name pattern, and the name shows as a link that reveals it in Finder.
3. A recording is an operation: the card shows the command and a failure.

### D3. GIF and compressed video

1. For a recording, or a `.mov` or `.mp4` that the user picks: "Make GIF" (width 320, 480 or 640; 10 or 15 frames per second) and "Compress" (HEVC or H.264, 1080p or 720p).
2. Frames come from `AVAssetImageGenerator`, the GIF is written with ImageIO (`CGImageDestination`), compression uses `AVAssetExportSession`. The code lives in `DevHubData/Media/`; the layer check allows AVFoundation and ImageIO only there.
3. The result goes next to the source file. The work is an operation with progress.

### D4. Device frames

1. DevHub reads the frame of the simulator's device type from the Xcode on the Mac (`chromeIdentifier`, `chrome.json`, the PDF parts) and draws the screenshot into it with CoreGraphics. Nothing from Apple goes into the repository.
2. The screenshot uses `simctl io <udid> screenshot --mask=alpha`, so the round screen corners are cut.
3. "Add the device frame" is one saved switch for screenshots, GIFs and converted videos. A GIF frame is drawn under the frame with a hole for the screen; an MP4 gets the frame through a video composition. Recordings use `--mask=black`, so the screen corners match the bezel.
4. `chrome.json` is not documented. A fixture test pins the format. When a frame is missing or cannot be read, DevHub saves the plain screenshot and says why.

### D5. Build insights

1. Two sources: the builds of DevHub (start, end, scheme, configuration, checkout or worktree, branch, result, errors, warnings) and the builds of Xcode from `LogStoreManifest.plist` of the project's DerivedData folder.
2. Xcode deletes old logs, so DevHub keeps its own history in a JSON file under Application Support, one entry per `uniqueIdentifier`. No timer: DevHub reads the manifests when the insights open and after its own build.
3. The view: today and this week (count, total time, median, longest), by scheme and by branch, and the last builds with their status. A short line on Home ("12 builds today, 18 min").
4. Later: the slowest targets from `-showBuildTimingSummary` for DevHub builds.

### D6. Snapshots of the app state

1. **App snapshot.** A copy of the data container and the app group containers of the app, saved under `~/Library/Application Support/DevHub/Snapshots/<bundle ID>/<name>/` with APFS clones (`cp -c -R`: fast, and it takes almost no space until the files change). Restore: `simctl terminate`, replace the contents of the containers, then load each preferences file with `simctl spawn <udid> defaults import <plist path> <file>` on a booted simulator, so `cfprefsd` gets the values. A snapshot can go to another simulator with the same app. It has no keychain items.
2. **Device snapshot, with the keychain.** The keychain is shared by all apps of a simulator and may be bound to that device, so the keychain is saved with the whole device: shut the simulator down, clone `Devices/<udid>/data` with APFS clones, and restore by swapping the folder while the simulator is shut down. Only to the same simulator. "Restore the keychain only" copies `data/Library/Keychains` back, which changes the keychain items of every app on that simulator.
3. A keychain export for one app needs code inside the app (`SecItem`), so it waits for D7.
4. The snapshot list shows the name, the date, the size and Delete. The sizes come from `du`, because clones share space.

### D7. Network monitor

Today the Network tab sees only the requests that the app sends to the DevHub server (forward, patch and delay rules for the base URL). Other hosts, SDK traffic and builds that do not point at DevHub are not seen.

Options:

1. **Companion package.** A Swift package for the debug build of the app. A `URLProtocol` in every `URLSessionConfiguration` sends each request and response to DevHub: `localhost` on a simulator, Bonjour on a device. The same channel can later carry live defaults, a keychain export, a memory warning and commands.
2. **Injected library.** The same code built as a dylib for the simulator and loaded with `SIMCTL_CHILD_DYLD_INSERT_LIBRARIES` when DevHub launches the app. No change to the app, simulator only, and a new iOS version may break it.
3. **HTTPS proxy.** A proxy in DevHub, the root certificate added with `simctl keychain <udid> add-root-cert`, and the proxy set for the Mac. It sees every app, but it changes the network settings of the Mac, and certificate pinning blocks it.

Decision (owner, 2026-11-01): options 1 and 2 from one source, option 2 (the injected library) first.

### D8. Real devices

1. A "Devices" section in the Simulators tab from `xcrun devicectl list devices --json-output <file>`: name, OS version, "Connected" (`tunnelState == connected`) or "Not connected". A device is a `Simulator` value with `isPhysical` and its own `runtime`; its id is the hardware UDID, which `xcodebuild` and `devicectl` both take. The row hides every simulator-only action. One port, `DeviceRepository`, for everything that runs through `devicectl`; the use cases branch on `BuildRequest.isPhysicalDevice` and `IdentityLaunch.simulator.isPhysical`.
2. Build for a device: the same `xcodebuild` with `-destination id=<udid>` plus `-allowProvisioningUpdates`, with the automatic signing of the project. DevHub does not manage certificates or profiles. Checked: `xcodebuild -showdestinations` lists the device with that id.
3. Install and launch: `devicectl device install app --device <id> <App.app>`, `devicectl device process launch --device <id> --terminate-existing --environment-variables <JSON> <bundle ID> <args>`. The launch profile (`env`, `args`, `defaults`) and the device ID work as on a simulator. `defaults` go through `copy from`, `defaults write` on the Mac and `copy to` on `Library/Preferences/<suite>.plist` of the app data container (checked on an iPhone 2026-11-07: the key survived a relaunch; `appGroupDataContainer` listing failed with CoreDevice error 3, and the app kept its group suite plist in its own container). Clean install: `uninstall app`, then install the last build; no keychain reset.
4. Deferred (owner, 2026-11-07): the console and the Logs tab (`--console` or a syslog tool), the mock server on a device (needs a listener on the LAN address and a local network permission in the app), Run & Attach (the attacher clicks a simulator destination), deep links, push, app data and app snapshots (D6) for a device.
5. The device must be paired, unlocked and in Developer Mode. A device name is personal: it never goes into a committed file, and tests use sample names.

## Plan

- [x] 1. D2 video recording.
- [x] 2. D3 GIF and compressed video.
- [x] 3. D4 device frames on screenshots.
- [x] 3b. D4 device frames on GIF and video.
- [ ] 4. D5 build insights.
- [ ] 5. D6 app snapshots.
- [ ] 6. D6 device snapshots with the keychain.
- [x] 7. D8 devices: list, install, launch with profiles and the device ID, clean install, identity panel.
- [ ] 7b. D8 devices: console in the Logs tab, mocks. Run & Attach is done in ADR 017 step 10.
- [ ] 8. D8 devices: build with signing, app data copy.
- [x] 9a. D1.1 open Simulator.app or Device Hub by the Xcode in use; the menu item and the example config follow.
- [ ] 9. D1.2 check the rest on Xcode 27, after the owner installs Xcode 27.
- [ ] 10. D7 network monitor: the injected library first, then the companion package.

## Step log

| Commit | What it did |
|---|---|
| `7791ebd` | Step 1: video recording: `SimulatorSettingsRepository.record` (`simctl io recordVideo --codec=h264 --force`), `ShellRunner.stream(…, stop: .interrupt)` and `ProcessStop`, recording state and operation in `SimulatorQAStore`, Record and Stop in the QA panel, `PresentationAssembly.prepareForQuit()` from `applicationWillTerminate`. |
| `b6dc8e2` | Step 2: GIF and compressed video: `MediaRepository`, `AVMediaRepository` in `DevHubData/Media/` (`AVAssetImageGenerator` and `CGImageDestination`, `AVAssetExportSession`), `MediaOutputPolicy`, `MediaStore` and `MediaChoice`, Convert in the QA panel, the AVFoundation and ImageIO rule in `check-layers.sh`. |
| `2ca80b0` | Step 3: device frames on screenshots: `DeviceChromeLocator`, `DeviceChromeParser`, `DeviceFrameLayout`, `DeviceFrameRenderer` in `DevHubData/Media/`, `MediaRepository.addFrame`, `--mask=alpha` screenshots, the saved switch in `SimulatorQAStore`, fixture and integration tests. |
| `6eb9711` | Step 3b: device frames on GIFs and MP4 videos: `DeviceFrameOverlay`, `FramedVideoComposition` (`AVVideoComposition.Configuration`), the outer outline from `paths.simpleOutsideBorder`, `framedFor` on `makeGIF` and `compress`, `MediaOutputPolicy.gifFrames` over the sample times of a variable frame rate recording, GIF written in one step, `--mask=black` recordings, `SimulatorQAStore.addsDeviceFrame`. |
| `7074404` | Rule: never name another project in a doc, a comment, a commit, a test or the code (`.claude/rules/anonymity.md`). |
| `d95514e` | Tags from the status script (`AppStateReport.tags`, `ScriptViewTag` with `icon` and `hint`, `ConfigTagMapper`) and `launch.profiles[].tint` for the profile tag. |
| `03ab6a8` | The Xcode tag in the run bar (`XcodeTagMapper`, `XcodeSelectionStore.refreshIfNeeded`, `XcodeInstallationRepository.installation(atDeveloperDir:)` for a Mac where Spotlight does not find Xcode). |
| `e3031f9` | Step 7: physical devices: `DeviceRepository` and `DevicectlDeviceRepository` (`DevicectlRunner`, the list, launch and app list parsers), `Simulator.isPhysical` and `runtime`, the Devices section, the device branch of `AppInstallStep`, `BuildAndRunUseCase`, `CommandRunUseCase` and `LaunchInstalledAppUseCase`, `ProductLocator` with the `iphoneos` folder, `TargetFallbackPolicy`, `DEVHUB_SIMULATOR_KIND`, the hidden simulator-only actions and the disabled Run & Attach. Checked with a full Build & Run on an iPhone over Wi-Fi. |
| `57f3f27` | Config schema closed for a chat command tab (`docs/customization.md`): shared tab `inputs` (`CustomTabInputsBar`, `configActions.tabInputs`), `recent: true` values with a clock menu, `confirm` per choice option (`ActionConfirmationPolicy`), `copy` runs with a live preview and the Recent section (`ConfigCopyRecord`, `CustomTabHistorySection`). |
| `de740f8` | Step 9a: Device Hub on Xcode 27: `SimulatorApp` and `SimulatorRepository.simulatorApp()`, `SimulatorAppLocation` (Simulator.app of the project's developer dir, else `DeviceHub.app` of that Xcode, opened with `devices://device/open?id=<udid>` after `simctl boot`), the row menu title "Open in Simulator" or "Open in Device Hub", the example `list-devices` script. |
