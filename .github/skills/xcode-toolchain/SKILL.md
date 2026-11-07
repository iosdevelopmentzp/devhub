---
name: xcode-toolchain
description: "Verified commands and traps for xcodebuild, simctl, DerivedData, product lookup, code signing on simulator builds, launch environment and defaults, app containers, clean install, log streams and attaching Xcode, with the Data repositories and Domain use cases that run them (XcodeBuildRepository, BuildOutputParser, ProductLocator, XcodeContainer, XcodeDerivedDataRepository, SimctlSimulatorRepository, SimctlAppLaunchRepository, SimctlMessagingRepository, SimctlAppLogRepository, AccessibilityXcodeAttacher, BuildAndRunUseCase, AppInstallStep). Load before touching Build & Run, Simulators, Logs or anything that runs xcrun or xcodebuild."
---

# Xcode Toolchain

Every command below runs through `ShellRunner` (see `data-layer`), so it shows in the Output panel. Paths are
relative to `Packages/DevHubKit/Sources/`.

| Area | Code |
|---|---|
| Build | `DevHubData/Build/`: `XcodeBuildRepository`, `BuildOutputParser`, `BuildStepThrottle`, `ProductLocator`, `XcodeContainer` |
| Tests | `DevHubData/Build/`: `XcodeTestRepository` (`xcodebuild … -resultBundlePath <bundle> test`), `TestOutputParser` (XCTest and Swift Testing lines), `SourceFileLocator`, `XcresultParser` (`xcrun xcresulttool get test-results tests --path <bundle>`: `Test Case` nodes under a `Unit test bundle` or `UI test bundle` and a `Test Suite`; a `Failure Message` starts with `File.swift:line:`; the identifier is `<class>/<test>()`, so `-only-testing:` takes `<target>/<class>/<test>`), `XcresultAttachmentParser` (`export attachments … --output-path <dir>` writes `manifest.json` into the folder, not to stdout; `--only-failures` keeps only attachments made at the failure, so DevHub exports all and filters by test); `RunTestsUseCase` (Domain) boots the simulator first; `TestRunsStore` (Presentation) keeps one `TestRun` per worktree |
| DerivedData | `DevHubData/Workspace/XcodeDerivedDataRepository` |
| Simulators | `DevHubData/Simulators/`: `SimctlSimulatorRepository`, `SimctlAppLaunchRepository`, `SimctlMessagingRepository`, `SimctlAppDataRepository`, `DefaultsExportParser`, `AppGroupListParser`, `AppDataScanner`, `SimctlRunner`, `SimctlListParser`, `ContainerLocator`, `ProfileDefaultsPlan`, `AppURLSchemeParser`, `Dictionary+ChildEnvironment` |
| Logs | `DevHubData/Logs/`: `SimctlAppLogRepository`, `AppLogParser`, `LogRedactor`, `LogCounter`; `AppLogPredicatePolicy` (Domain) |
| Attach | `DevHubData/Workspace/AccessibilityXcodeAttacher` |
| Pipelines | `DevHubDomain/UseCases/`: `BuildAndRunUseCase`, `CommandRunUseCase`, `AppInstallStep`, `LaunchInstalledAppUseCase`, `MockLaunchPreparation` |
| Project detection | `DevHubData/Workspace/XcodeProjectDetector` (scheme and bundle ID of a new project) |

## Which Xcode runs

`ShellRunner` adds `DEVELOPER_DIR` to `xcodebuild`, `xcrun` and `xed` when the selected project has an Xcode
(Settings → Projects, else `xcode.developerDir`). `XcodeSelectionStore` sets it through
`ToolEnvironmentRepository` (`ShellToolEnvironmentRepository` writes `shell.developerDir`). `open -a` uses
`shell.developerDir.xcodeAppName()` (the `.app` path, else `Xcode`). `SpotlightXcodeInstallationRepository` lists
the installed apps with `mdfind kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'` and reads
`Contents/version.plist`; `xcode-select -p` gives the system default. Never pass the folder in a port call.

## Build and Run pipeline (`kind: xcode`)

`BuildAndRunUseCase.run(_:)` returns an `AsyncThrowingStream<BuildEvent, Error>` and runs these steps. `BuildStore`
reads the stream.

```
xcrun simctl boot <udid>                                                     exit 149 = already booted = success
xcodebuild <container> -scheme S -configuration C -destination id=<udid> clean                    only when request.incremental is false
xcodebuild <container> -scheme S -configuration C -destination id=<udid> ONLY_ACTIVE_ARCH=YES build    streamed
locate the .app (ProductLocator), bundle ID from <app>/Info.plist CFBundleIdentifier
xcrun simctl bootstatus <udid>
[clean install]  xcrun simctl uninstall <udid> <bundleID> · xcrun simctl keychain <udid> reset
xcrun simctl install <udid> <app>
[profile defaults]  xcrun simctl get_app_container <udid> <bundleID> data|<group suite> · xcrun simctl spawn <udid> defaults write <plist> <key> -string <value>
[window]  open <developer dir>/Applications/Simulator.app --args -CurrentDeviceUDID <udid>   (Xcode 27: simctl boot, then open devices://device/open?id=<udid>)
xcrun simctl launch --terminate-running-process [--wait-for-debugger] <udid> <bundleID> [arguments]
[attach]  AccessibilityXcodeAttacher.attach(pid:simulatorUDID:projectPath:container:)
```

- `<container>` is `-workspace <path>` or `-project <path>`. `XcodeContainer.locate(in:preferred:)` takes
  `xcode.container` from config, else the first `.xcworkspace`, else the first `.xcodeproj` in the folder.
- The launch environment and arguments come from the `LaunchPlan` of the profile. `SimctlSimulatorRepository.launch`
  prefixes every key with `SIMCTL_CHILD_` (`Dictionary.childEnvironment`). `MockLaunchPreparation` adds the mock
  server URL under `network.baseURLVariable`.
- The process ID is the last `: <pid>` of the `simctl launch` output (`LaunchOutput.pid(from:)`).
- `kind: command` projects use `CommandRunUseCase`: boot, `build.command`, `run.command`, then the same
  `AppInstallStep` when a command printed `@devhub {"app": "<path>"}`.

### Never do this

- `CODE_SIGNING_ALLOWED=NO` or any signing override on a build that will run. Embedded frameworks stay unsigned and
  dyld on Apple silicon stops the app at launch: "Library not loaded: @rpath/<Framework>". `xcodebuild` signs ad hoc
  for a simulator destination by itself.
- `-derivedDataPath`. The shared DerivedData folder reuses the cache of the Xcode build of the same checkout.
- A fake percentage. `xcodebuild` has no total. Show an indeterminate bar and the step text.

### Step text (`BuildOutputParser.step(from:)`)

The first word of a line that does not start with a space maps to a verb: `SwiftCompile CompileSwift
CompileSwiftSources SwiftDriver SwiftEmitModule CompileC ProcessPCH CompileXIB CompileStoryboard CompileMetalFile` →
Compiling; `CompileAssetCatalog` → Compiling assets; `Ld Libtool LinkStoryboards` → Linking; `PhaseScriptExecution` →
Running script; `CodeSign` → Signing; `CopySwiftLibs CpResource Copy PBXCp` → Copying; `ProcessInfoPlistFile` →
Processing Info.plist; `GenerateDSYMFile` → Generating dSYM; `Touch Validate RegisterExecutionPolicyException` →
Finishing. `Resolve Package Graph` and `Resolved source packages` → Resolving packages. The target comes from
`(in target '…')`: "Compiling · ExampleApp". `BuildStepThrottle` sends at most one step every 200 ms.

`BuildOutputParser.error(from:)`: a line with `error: ` is an error; the first one is the failure message (the file
name only, when the line starts with `/`).

### Product lookup, in this order

1. `BuildOutputParser.appPath(from:)` collects paths from `Touch`, `Validate`, `CodeSign` and
   `RegisterExecutionPolicyException` lines that end with `.app` (`\ ` unescaped). `ProductLocator` takes the first
   one that contains `<Configuration>-iphonesimulator/` and exists.
2. The DerivedData folder of the checkout → `Build/Products/<Configuration>-iphonesimulator/*.app`: the one named
   like the scheme, else the only one, else the newest.
3. `xcodebuild … -showBuildSettings -json` (slow, about 30 s on a big project): the entry with
   `PRODUCT_TYPE == com.apple.product-type.application`, then `TARGET_BUILD_DIR/WRAPPER_NAME`.

### DerivedData (`XcodeDerivedDataRepository`)

- Root: `IDECustomDerivedDataLocation` in the `com.apple.dt.Xcode` preferences (`CFPreferencesCopyAppValue`). A
  relative value is under the home folder. The default is `~/Library/Developer/Xcode/DerivedData`.
- `folder(forCheckout:)`: the folder whose `info.plist` has a `WorkspacePath` whose parent folder equals the checkout
  (standardized, lowercased).
- `size(of:)` runs `du -sk`. `remove(_:)` deletes a folder only when it is under the root.

### Schemes (`XcodeContainer.schemeNames()`)

`.xcscheme` files under `<container>/xcshareddata/xcschemes` and `<container>/xcuserdata/*/xcschemes`; for a workspace
also under the sibling `.xcodeproj` folders. Sorted with `localizedStandardCompare`.

## Simulators

| Need | Command and code |
|---|---|
| List | `xcrun simctl list devices available -j` (`SimctlSimulatorRepository.list`, `SimctlListParser`). Runtime `com.apple.CoreSimulator.SimRuntime.iOS-26-4` → "iOS 26.4". Only iOS runtimes; newest first |
| Boot, shutdown | `simctl boot`, `simctl shutdown`; exit 149 means "already in that state" and counts as success (`SimctlRunner.run(_:allowingExit:failure:)`) |
| Erase | `simctl shutdown`, then `simctl erase` |
| Wait for boot | `simctl bootstatus <udid>` |
| Open the window | `SimctlSimulatorRepository.openInSimulatorApp`, the app found by `SimulatorAppLocation` from the developer folder (`ShellRunner.developerDir`, else `xcode-select -p`). Xcode 26: `open <developer dir>/Applications/Simulator.app --args -CurrentDeviceUDID <udid>`. Xcode 27 has no Simulator.app: `<Xcode>/Contents/Applications/DeviceHub.app` (`com.apple.dt.Devices`); `simctl boot <udid>`, then `open devices://device/open?id=<udid>` (Device Hub shows no window for a device that is still shut down), else `open -a <DeviceHub path>`. Neither found: `open -a Simulator …`, then the Device Hub steps with `open -b com.apple.dt.Devices` |
| Installed app count without booting | folders under `~/Library/Developer/CoreSimulator/Devices/<udid>/data/Containers/Bundle/Application` (`installedAppCounts(udids:)`) |
| User apps | `simctl listapps <udid>` (plist text), `ApplicationType == User` |
| Uninstall | `simctl uninstall <udid> <bundleID>`. A shut-down device is booted, waited for, then shut down again (`whileBooted`) |
| App container | `simctl get_app_container <udid> <bundleID> app\|data\|<group>`. It fails on a shut-down device; `ContainerLocator.find` then reads `.com.apple.mobile_container_manager.metadata.plist` (`MCMMetadataIdentifier`) under `Bundle/Application/*` or `Data/Application/*` |
| Profile defaults | `ProfileDefaultsPlan`: a `group.` suite writes into that group container, any other suite into the `data` container. `simctl spawn <udid> defaults write <container>/Library/Preferences/<suite>.plist <key> -string\|-bool\|-integer\|-float <value>` |
| Installed app facts | `SimctlAppLaunchRepository.inspect`: version from `Info.plist`, identity marker with `grep -q -a -F` in the executable and `*.debug.dylib`, stored profile from the preferences plist |
| Clean install without a build | `SimctlAppLaunchRepository.cleanInstall`: copy the installed app with `ditto` to `~/Library/Caches/DevHub/Apps/<udid>-<bundleID>.app` (else the last built product), `simctl terminate`, `uninstall`, `keychain reset`, `install` |
| App data | `SimctlAppDataRepository`: `get_app_container <udid> <bundleID> data` and `groups`, `spawn <udid> defaults export <plist> -` per suite (parsed by `DefaultsExportParser`), `defaults write\|delete <plist> <key>`; reset: `simctl terminate`, `defaults delete <plist>` (exit 1 = missing domain), then `AppDataScanner` removes the files. Never edit a plist file directly: `cfprefsd` in the simulator caches it |
| Deep link | `simctl openurl <udid> <url>` (`SimctlMessagingRepository.openURL`) |
| URL schemes | `CFBundleURLTypes` in the installed app `Info.plist` (`AppURLSchemeParser`) |
| Push | `simctl push <udid> <bundleID> <file.apns>`, a temporary file with the JSON payload |
| Disk cleanup | `XcodeDiskCleanupRepository`: `simctl list devices unavailable -j` (`SimctlUnavailableDeviceParser`, the size is the sum of `dataPathSize`) and `simctl runtime list -j` (`SimctlRuntimeListParser`, only `deletable` runtimes, `sizeBytes`, `lastUsedAt`); delete with `simctl delete unavailable` and `simctl runtime delete <identifier>`. The folders (DerivedData by `WorkspacePath`, Archives, `<platform> DeviceSupport`, SwiftPM and CocoaPods caches) come from `DiskFolderScanner`, are measured with `du -sck` and deleted with `rm -rf --` after `DiskCleanupPolicy.isRemovable` |

## Physical devices

A paired iPhone or iPad is a `Simulator` value with `isPhysical == true` and its OS in `runtime`; its `id` is the hardware UDID (`00008110-…`), which `xcodebuild -destination id=` and `devicectl --device` both accept. Everything runs through `xcrun devicectl` (`DevHubData/Devices/`, `DevicectlDeviceRepository`, `DevicectlRunner`). `devicectl` prints human text; a script reads its result only through `--json-output <file>` (`DevicectlRunner.json` writes a temporary file and deletes it).

| Need | Command and code |
|---|---|
| List | `xcrun devicectl list devices --json-output <file>` (`DevicectlListParser`): `hardwareProperties.udid`, `deviceProperties.name`, `osVersionNumber`, `deviceType` iPhone or iPad, `platform` iOS; `connectionProperties.tunnelState == connected` is "connected" (`state == .booted`), anything else "not connected". Watches, `reality: virtual` and records without hardware are dropped |
| Build | the same `xcodebuild` as a simulator with `-destination id=<udid>` plus `-allowProvisioningUpdates`; the project signs itself (automatic signing with a team, Xcode logged in). The product lands in `Debug-iphoneos` |
| Install | `devicectl device install app --device <udid> <App.app>` |
| Uninstall | `devicectl device info apps --device <udid> --bundle-id <id> --json-output <file>` first; when the app is listed, `devicectl device uninstall app --device <udid> <bundle ID>` |
| Launch | `devicectl device process launch --device <udid> --terminate-existing --environment-variables '<JSON>' --json-output <file> <bundle ID> <args>`. The environment is a JSON dictionary with sorted keys (`DevicectlDeviceRepository.launchArguments`); no `SIMCTL_CHILD_` prefix. The pid is `result.process.processIdentifier` (`DevicectlLaunchParser`). The app opens in the foreground. Error 10004 ("process identifier could not be determined") was seen once right after a terminate |
| Installed app facts | `devicectl device info apps --bundle-id` gives the version (`DevicectlAppListParser`). The identity markers are read with `AppBundleMarkers` from the last built product on the Mac (`BuildLookup.lastBuiltAppPath()`), only when its `Info.plist` has the same bundle ID; the device binary cannot be read |
| Profile defaults and stored profile | `devicectl device copy from --domain-type appDataContainer --domain-identifier <bundle ID> --source Library/Preferences/<suite>.plist --destination <local>`, `defaults write <local folder>/<suite> <key> -string\|-bool\|-integer\|-float <value>` on the Mac, then `copy to` with the same paths (`ProfileDefaultsPlan.localWriteArguments`, `preferencesPath`). Checked on an iPhone: the copied key survived a relaunch of the app. The plist of a `group.` suite is read from the app data container too: `appGroupDataContainer` listing failed on that phone (CoreDevice error 3), and the app kept its group suite plist under its own `Library/Preferences` |
| Clean install | `uninstall` then `install` of the last built product. No keychain reset on a device |
| Not available | `log stream` (no devicectl command; `idevicesyslog` or `pymobiledevice3` would be a new tool), the mock server (listens on 127.0.0.1 only), Run & Attach (`AccessibilityXcodeAttacher` clicks a simulator destination), `openurl`, `push`, erase, app data, QA settings. The row hides those actions |

Facts of the paired devices (name, serial, ECID, UDID) are personal: `DevicectlListFixture` uses sample values.

## Logs

```
xcrun simctl spawn <udid> log stream --style ndjson --level debug --predicate 'subsystem == "<s>"'   or   'process == "<Executable>"'
```

- `AppLogPredicatePolicy.predicate(for:)` uses the subsystem when it is set, else the process. With neither there is
  no predicate.
- `AppLogParser.parse(_:id:)` reads `timestamp` (`yyyy-MM-dd HH:mm:ss.SSSSSSZ`, `en_US_POSIX`), `messageType`
  (`Debug Info Default Error Fault`), `subsystem`, `category`, `eventMessage`. It redacts the message with
  `LogRedactor` before the line leaves Data: `Bearer …`, JWTs, and values after `authorization`, `x-auth-token`,
  `access_token`, `refresh_token`, `id_token`, `token`, `password`, `secret`, `api_key`.
- The process name is `CFBundleExecutable` of the installed app (`SimctlAppLogRepository.executableName`, through
  `simctl get_app_container … app`). The bundle ID comes from `IdentityLookup.bundleID(for:)`: the last launch from
  DevHub, else `xcode.bundleIDs` and `xcode.bundleID`, else the project settings. `LogsStore` falls back to the scheme name.
- Only `os_log` and `Logger` lines arrive. `print()` does not.
- The level filter runs in the app. The stream always uses `--level debug`.
- `LogsStore` adds lines every 150 ms. `LogStream.capacity` is 5 000 lines per stream; older lines go to `dropped`.
  Pause keeps new lines in `pending`.
- The command log entry has the kind `appLog`, so it records no lines. Nothing goes to disk.
- A stream that ends with a non-zero code and no cancel throws `AppLogError.streamStopped`.

## Run & Attach (Xcode)

`AccessibilityXcodeAttacher.attach(pid:simulatorUDID:projectPath:container:)`:

1. `AXIsProcessTrusted()`. When false: `AXIsProcessTrustedWithOptions` with the prompt, then
   `XcodeAttachError.accessibilityNotGranted`.
2. `simctl launch --wait-for-debugger` gave the PID before this step.
3. `open -a Xcode <container>`. The container is `xcode.container` (passed as `container`), else the first `.xcworkspace`, else the first `.xcodeproj` (`XcodeContainer.locate(in:preferred:)`). When Xcode had no window, wait for one (`System Events` window count, every 3 s, up
   to 150 s), then 6 s; else 1.5 s.
4. `osascript`: select the run destination whose `device identifier` is the UDID in `run destinations of workspace
   document`.
5. `osascript` on `System Events`, process `Xcode`: click "Attach to Process by PID or Name…" in the Debug menu, `set
   value of text field 1 of sheet 1 of window 1` to the PID (keystrokes do not reach the field), click "Attach".
6. Poll `ps -o stat= -p <pid>` every second for 25 s. A state that still starts with `T` means stopped →
   `XcodeAttachError.stillStopped(pid)` with the manual steps.

The app target needs `INFOPLIST_KEY_NSAppleEventsUsageDescription` (set in `project.pbxproj`). A rebuilt ad hoc binary
can lose the Accessibility permission; Settings → Doctor shows it.

## Tests

- Parsers: `BuildOutputParserTests`, `SimctlListParserTests`, `AppLogParserTests`, `LogRedactorTests` with fixtures.
- File code over `TemporaryDirectory`: `XcodeContainerTests`, `ProductLocatorTests`, `ContainerLocatorTests`
  (`SimulatorContainerTree` in `DevHubDataTests/Support/`).
- Pipelines over spies: `BuildAndRunUseCaseTests`, `CommandRunUseCaseTests`, `LaunchInstalledAppUseCaseTests`.
- A real run: `DEVHUB_BUILD_RUN=<simulator name or UDID>` with `DEVHUB_BUILD_PROFILE`, `DEVHUB_BUILD_BRANCH` and
  `DEVHUB_LAUNCH_ID` (`build-and-run`).
