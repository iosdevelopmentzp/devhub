---
name: xcode-toolchain
description: "Verified commands and traps for xcodebuild, simctl, DerivedData, product lookup, code signing on simulator builds, launch environment, app containers, clean install, log streams and attaching Xcode. Load before touching Build & Run, Simulators, Logs or anything that runs xcrun or xcodebuild."
---

# Xcode Toolchain

Read `docs/SPEC.md` section 8.5 to 8.7 for the full list. This skill is the short form with the commands.

## Build and run pipeline (`kind: xcode`)

```
xcrun simctl boot <udid>                                     exit 149 = already booted = success
xcodebuild <container> -scheme S -configuration C -destination id=<udid> clean      only when Fast is off
xcodebuild <container> -scheme S -configuration C -destination id=<udid> ONLY_ACTIVE_ARCH=YES build     streamed
locate .app  →  bundle ID from <app>/Info.plist CFBundleIdentifier
[clean install]  simctl terminate · simctl uninstall · simctl keychain <udid> reset
xcrun simctl install <udid> <app>
open -a Simulator --args -CurrentDeviceUDID <udid>
xcrun simctl launch --terminate-running-process [--wait-for-debugger] <udid> <bundleID> [args]     env through SIMCTL_CHILD_*
```

`<container>` is `-workspace <path>` or `-project <path>`: first `.xcworkspace`, else first `.xcodeproj` in the folder.

### Never do this

- `CODE_SIGNING_ALLOWED=NO` or any signing override on a build that will run. Embedded frameworks stay unsigned and dyld on Apple silicon kills the app at launch: "Library not loaded: @rpath/<Framework>". `xcodebuild` ad-hoc signs for a simulator destination by itself.
- `-derivedDataPath`. Sharing Xcode's DerivedData reuses the cache of the Xcode build of the same checkout.
- A fake percentage. `xcodebuild` has no total. Indeterminate bar plus a step text.

### Step text

First token of a line → verb: `SwiftCompile CompileSwift CompileSwiftSources SwiftDriver SwiftEmitModule CompileC ProcessPCH CompileXIB CompileStoryboard CompileMetalFile` → Compiling; `CompileAssetCatalog` → Compiling assets; `Ld Libtool LinkStoryboards` → Linking; `PhaseScriptExecution` → Running script; `CodeSign` → Signing; `CopySwiftLibs CpResource Copy PBXCp` → Copying; `ProcessInfoPlistFile` → Processing Info.plist; `GenerateDSYMFile` → Generating dSYM; `Touch Validate RegisterExecutionPolicyException` → Finishing; lines that start with `Resolve Package Graph` or `Resolved source packages` → Resolving packages. The target comes from `(in target '…')`. Lines that contain `error: ` are errors; the first one is the failure message (file name only when it starts with `/`).

### Product lookup, in this order

1. `Touch`, `Validate`, `CodeSign`, `RegisterExecutionPolicyException` lines whose path ends with `.app` and contains `<Configuration>-iphonesimulator/` (unescape `\ `). Check that the path exists.
2. The DerivedData folder whose `info.plist` has `WorkspacePath` whose parent folder equals the checkout (standardized, case-insensitive) → `Build/Products/<Configuration>-iphonesimulator/*.app`: the one named like the scheme, else the only one, else the newest.
3. `xcodebuild … -showBuildSettings -json` (slow, about 30 s on a big project): the entry with `PRODUCT_TYPE == com.apple.product-type.application`, `TARGET_BUILD_DIR/WRAPPER_NAME`.

### DerivedData

Root: `IDECustomDerivedDataLocation` in `com.apple.dt.Xcode` preferences (`CFPreferencesCopyAppValue`), relative values under the home folder, default `~/Library/Developer/Xcode/DerivedData`. Delete a folder only when its path is under that root. Size: `du -sk`.

### Schemes

`.xcscheme` names under `<container>/xcshareddata/xcschemes` and `<container>/xcuserdata/*/xcschemes`; for a workspace also under sibling `.xcodeproj` folders. Fall back to the configured scheme name.

## Simulators

| Need | Command |
|---|---|
| List | `xcrun simctl list devices available -j` (`LiveSimulatorProvider`, parsed by `SimulatorListParser`) → `devices[runtimeID] = [{udid, name, state, deviceTypeIdentifier, isAvailable}]`; runtime `com.apple.CoreSimulator.SimRuntime.iOS-26-4` → platform and version from the suffix |
| Boot, shutdown, erase | `simctl boot`, `simctl shutdown` (149 ok), `simctl shutdown` then `simctl erase` |
| Wait for boot | `simctl bootstatus <udid>` |
| Open window | `open -a Simulator --args -CurrentDeviceUDID <udid>` |
| Installed app count without booting | folders under `~/Library/Developer/CoreSimulator/Devices/<udid>/data/Containers/Bundle/Application` |
| User apps | `simctl listapps <udid>` (plist text) filtered by `ApplicationType == User` |
| Uninstall | `simctl uninstall <udid> <bundleID>`; a shut-down device: boot, bootstatus, work, shutdown |
| App container | `simctl get_app_container <udid> <bundleID> app\|data`; fails when shut down → scan `…/data/Containers/Bundle/Application/*/` and `…/Data/Application/*/` for `.com.apple.mobile_container_manager.metadata.plist` with `MCMMetadataIdentifier == bundleID` |
| Defaults in the app container | booted: `simctl spawn <udid> defaults write <data>/Library/Preferences/<suite>.plist <key> -string <value>`; shut down: edit the plist with `PropertyListSerialization` (binary) |
| Clean install without a build | copy of the installed app kept with `ditto` under `~/Library/Caches/DevHub/Apps/<udid>-<bundleID>.app`, else the last built product; `terminate`, `uninstall`, `keychain reset`, `install` |
| Deep link | `simctl openurl <udid> <url>` |
| Push | `simctl push <udid> <bundleID> <file.apns>` with a JSON body that has `aps` |
| Launch PID | the last `: <pid>` of the `simctl launch` output |

## Logs

`xcrun simctl spawn <udid> log stream --style ndjson --level debug --predicate 'process == "<Executable>"'` (or `subsystem == "…"`). Fields: `timestamp` (`yyyy-MM-dd HH:mm:ss.SSSSSSZ`, `en_US_POSIX`), `messageType` (`Debug Info Default Error Fault`), `subsystem`, `category`, `eventMessage`. The executable name is `CFBundleExecutable` of the installed app: `simctl get_app_container <udid> <bundleID> app`, else the `Bundle/Application` folders, then `Info.plist` (`LiveSimulatorProvider.executableName`). A stream needs a process or a subsystem; with neither the store looks the executable up and shows an error when that fails. The provider filter is `subsystem` when set, else `process`. Only `os_log` / `Logger` lines arrive; `print()` does not. Redact before storing (`LogRedactor`): `Bearer …`, JWTs, values after `authorization x-auth-token access_token refresh_token id_token token password secret api_key`. Nothing on disk; the `CommandLog` entry is `appLog` and records no lines. Redaction runs inside `LogLineParser`, before a line reaches the store. The level filter works on the client; the stream always uses `--level debug`. Batch every 150 ms, cap 5 000 lines per stream with a dropped counter; Pause keeps a waiting count.

## Run & Attach (Xcode)

1. `AXIsProcessTrusted()`; when false, `AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true])`, report the System Settings path, stop.
2. `simctl launch --wait-for-debugger` → PID.
3. `open -a Xcode <container>`; when Xcode had no window, wait for one (`System Events` window count, up to 150 s) plus 6 s; else 1.5 s.
4. Select the run destination by UDID: `tell application "Xcode"` … `run destinations of workspace document` … `device identifier of (device of destination)` … `set active run destination`.
5. `System Events` on process `Xcode`: `click menu item "Attach to Process by PID or Name…" of menu 1 of menu bar item "Debug"`, `set value of text field 1 of sheet 1 of window 1 to "<pid>"` (keystrokes do not reach the field), `click button "Attach" of sheet 1 of window 1`.
6. Poll `ps -o stat= -p <pid>` for 25 s; a state that starts with `T` means still stopped → report the PID and the manual steps.

Needs `INFOPLIST_KEY_NSAppleEventsUsageDescription`. A rebuilt ad-hoc binary may need Accessibility again.
