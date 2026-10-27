---
name: panel-window
description: "How DevHub's menu bar item, panel and windows work: AppWindows with an NSStatusItem and an own MenuBarPanel instead of MenuBarExtra, open and close rules, WindowLayout (saved position and size, drag, resize, screen clamping), the pinned window and pull request windows, the status item image and title (StatusItemState, StatusItemImage, StatusItemTitle), the GlobalHotKey shortcut, Dock icon and login item, light appearance, the hints overlay. Load before changing anything in DevHubPresentation/Shell, WindowLayout, hints or the status item."
---

# Panel Window

Paths are relative to `Packages/DevHubKit/Sources/`. The window code lives in `DevHubPresentation/Shell/` (with
`WindowLayout` and `StatusItemState` in `DevHubPresentation/Shared/`), the hints in `DevHubUI/Hint/`, the hot key in
`DevHubData/Workspace/`.

## Why not `MenuBarExtra`

`MenuBarExtra(.window)` puts its panel back under the icon on every open and every resize, and the user cannot move
it. DevHub draws its own status item and panel. The SwiftUI `App` in `DevHub/DevHubApp.swift` has only an empty
`Settings` scene and `@NSApplicationDelegateAdaptor(AppContainer.self)`: `AppContainer` is the app delegate.

## Start

`AppContainer.init()` (DevHubComposition) builds `PresentationAssembly`. `applicationDidFinishLaunching(_:)` then
starts the shell:

```swift
let windows = AppWindows(assembly: assembly)
let hotKey = GlobalHotKey { windows.toggle() }
settings.onShortcutChange = { hotKey.register($0) }
windows.start()
hotKey.register(settings.values.globalShortcut)
#if DEBUG
DebugLaunch.apply(assembly: assembly, windows: windows)
#endif
```

`applicationShouldHandleReopen(_:hasVisibleWindows:)` (a click on the Dock icon, or `open` on the running app) calls
`windows.show()`.

`AppWindows.start()` sets the status item button, starts the observation of the layout, the status label and the app
activation, sets the activation policy (`SettingsStore.applyDockIcon()`), installs the main menu in window mode,
starts the usage and review polling, loads the config and the mock sets, and closes the panel on
`NSApplication.didResignActiveNotification`. In window mode it shows the main window when `layout.isWindowOpen` is
true (the window was open when DevHub quit).

## Two window modes

`AppSettings.windowMode` (`WindowMode`, Domain) is `.panel` (the default) or `.window`. Settings → General → Window
changes it; `SettingsStore.onWindowModeChange` calls `AppWindows.applyWindowMode(_:)`, which switches at once.

| | Panel mode | Window mode |
|---|---|---|
| Left click on the icon, global shortcut (`toggle()`) | `showPinnedOrPanel()`: the pinned window to the front, else toggle the panel | `toggleWindow()`: hide the main window when it is the key window of the active app on this desktop, else `showWindow()` |
| Dock click, "Show DevHub" (`show()`) | open the panel (or the pinned window) | `showWindow()` |
| Dock icon | only with "Show Dock icon" | always (`SettingsStore.showsDockIcon`) |
| Main menu | the SwiftUI default | `MainMenuBuilder` (DevHub, File, Edit, Window), installed again on every `didBecomeActiveNotification` |
| Pin button | shown | hidden |

`MainWindow` is an `NSWindow` with a title bar, `moveToActiveSpace`, the light appearance and the autosave name
`WindowLayout.mainAutosaveName` (the first time it takes the frame of the pinned window). `AppWindows` is its
delegate: `windowShouldClose(_:)` calls `hideWindow()` and returns false, so the close button and ⌘W only hide it.
`hideWindow()` orders the window out, saves `layout.isWindowOpen = false` and calls `NSApp.hide(nil)` when no pull
request window is open, so the focus goes back to the previous app. `showWindow()` orders a window that is visible on
another desktop out first, so `moveToActiveSpace` brings it to the current desktop.

## Pieces

| Type | Module, folder | Role |
|---|---|---|
| `AppWindows` | Presentation `Shell/` | `package final class`, `NSWindowDelegate`. Owns the `NSStatusItem`, the `MenuBarPanel`, the pinned window, the `MainWindow` and one window per pull request. `toggle()`, `show()`, `togglePanel()`, `showPanel()`, `togglePin()`, `showWindow()`, `hideWindow()`, `showPullRequestWindow(_:)` |
| `MainWindow`, `MainMenuBuilder` | Presentation `Shell/` | the window and the main menu of window mode |
| `MenuBarPanel` | Presentation `Shell/` | `NSPanel`: `.borderless`, `canBecomeKey` true, `isFloatingPanel`, `level = .statusBar`, `hidesOnDeactivate = false`, `isReleasedWhenClosed = false`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `animationBehavior = .none`, `isMovable = false`, clear background, shadow |
| `WindowLayout` | Presentation `Shared/` | `@Observable`: `size`, `panelTopLeft`, `openCount`, `isWindowOpen` (saved as `window.isOpen`); `panelFrame(anchor:anchorScreen:)`, `fit(_:)`, `resize(to:in:)`, `reset()`. Saves `window.size` and `window.panelTopLeft` through `KeyValueStore` |
| `WindowFrame` | Presentation `Shell/` | view modifier: a fixed `frame(width:height:)` from `layout.size` in the panel; a flexible frame with `minimumSize` in the pinned window that writes its size back to `layout` |
| `RootView` | Presentation `Shell/` | usage strip, `HeaderView`, `FeatureTabBar`, `SearchFilterBar`, the selected tab or `NoProjectState`, `OutputPanel`, `FooterView`; the palette overlay, `HintOverlay`, `ToastView` |
| `PanelDragArea`, `WindowDragArea` | Presentation `Shell/` | the header background moves the panel; a double click puts it back under the icon |
| `ResizeGrip` | Presentation `Shell/` | in the footer: a drag changes `layout.size`; a double click sets 720 × 820 |
| `WindowAppearance`, `HostWindowReader` | UI | set the window appearance from the view tree; give a view its `NSWindow` |
| `GlobalHotKey` | Data `Workspace/` | Carbon `RegisterEventHotKey`, no Accessibility needed |

Environment values for the shell: `\.isPinnedWindow` (DevHubUI), `\.togglePin`, `\.openPullRequestWindow` and
`\.panelOpenCount` (DevHubPresentation). `AppWindows.hostingController(isPinned:)` sets the first three on
`RootView().inject(assembly)`; `RootView` sets `\.panelOpenCount`.

## Open and close

- The first `showPanel()` creates the `NSHostingController` and keeps it. Later opens add 1 to `layout.openCount`.
  Every tab view and `RootView` use `.task(id: openCount)` to refresh on each open.
- `showPanel()` sets the frame, calls `NSApp.activate()`, then `makeKeyAndOrderFront`, highlights the status item
  button and installs a global mouse-down monitor (`.leftMouseDown`, `.rightMouseDown`, `.otherMouseDown`).
- The panel closes on a click outside DevHub (the monitor), on `didResignActiveNotification`, and on a second click
  on the status item. `closePanel()` removes the monitor.
- Left and right click on the status item both toggle the panel. There is no status item menu.
- `Notifier.panelShown(_:)` hears every open and close, so notifications show only while the panel and the pinned
  window are closed. The main window counts as shown only while it is visible, not minimized and DevHub is the
  active app.

## Position and size

- The anchor is the status item button frame in screen coordinates: `x = midX - width / 2`, `y = minY - 4`. A saved
  `panelTopLeft` wins over the anchor. The top-left point uses AppKit screen coordinates (y is the top edge).
- `panelFrame(anchor:anchorScreen:)` picks the screen that contains the point (else the screen of the icon, else
  the main screen), takes `visibleFrame` inset by `screenInset` (12), clamps the size and the point to that area,
  writes a moved point back and returns the frame.
- `AppWindows.observeLayout()` watches `size` and `panelTopLeft` with `withObservationTracking` and starts the
  observation again after each change. When `panelTopLeft` becomes nil (double click on the header), the panel goes back to the icon.
- `resize(to:in:)` limits the size to the room between the top-left corner and the screen edge, so the grip stays on
  the screen. Sizes never go below `WindowLayout.minimumSize` (640 × 560). The default is `defaultSize` (720 × 820).

## Pinned window

The pin button in `HeaderView` calls `\.togglePin`. `togglePin()` closes the panel and shows an `NSWindow` with
`[.titled, .closable, .miniaturizable, .resizable]`, `level = .floating`, `isReleasedWhenClosed = false`,
`contentMinSize = WindowLayout.minimumSize` and the autosave name `WindowLayout.pinnedAutosaveName`. The content is
the same `RootView` with `\.isPinnedWindow` true and `sizingOptions = [.minSize]`. `showPinnedOrPanel()` (the hot key)
brings the pinned window to the front when it is visible, else toggles the panel.

`showPullRequestWindow(_:)` opens one window per pull request (860 × 720, autosave name
`WindowLayout.pullRequestAutosaveName`) with `PullRequestWindowView`.

## Status item

`AppWindows.updateStatusLabel()` reads the stores inside `withObservationTracking` and sets the button image and
title again after every change.

```swift
let state = StatusItemState.state(isBuilding: assembly.build.isRunning, hasUnseenFailure: assembly.notifier.hasUnseenFailure)
statusItem.button?.image = StatusItemImage.image(for: state)
statusItem.button?.title = StatusItemTitle.text(
    usage: settings.values.showUsageInMenuBar ? usage.usage?.limits.first?.percentText : nil,
    reviewCount: settings.values.showReviewCountInMenuBar ? assembly.openPullRequests.reviewCount : nil,
    words: assembly.codeHostRemote.words
)
```

| Type | Folder | What it does |
|---|---|---|
| `StatusItemState` | `Shared/` | `.idle`, `.building`, `.failed`; `symbolName` (`hammer.fill` or `hammer.circle.fill`) and `showsFailureDot` |
| `StatusItemImage` | `Shell/` | a template SF Symbol; for `.failed` a drawn copy with a red dot in the corner (not a template) |
| `StatusItemTitle` | `Shell/` | the text after the icon: the usage percent and the review count, joined by ` · `. The count ends with `CodeHostWords.shortRequest`: "PR" on GitHub, "MR" on GitLab |

Tests: `StatusItemStateTests` and `StatusItemTitleTests` in `DevHubPresentationTests`.

## Global shortcut, Dock icon, login item

- `GlobalShortcut` (Domain) has the fixed list `optionCommandD` (⌥⌘D, the default), `controlOptionSpace`,
  `controlOptionD` and `off`. `GlobalShortcut+Carbon.swift` (Data) maps each case to a Carbon key code and modifiers.
- `GlobalHotKey.register(_:)` removes the old key and registers the new one on `GetApplicationEventTarget()`. The C
  handler posts `.devHubHotKeyPressed` on the main queue; the observer calls the `action` closure.
- `SettingsStore.onShortcutChange` fires when the user picks another shortcut in Settings.
- Dock icon: `SettingsStore.applyDockIcon()` calls `NSApp.setActivationPolicy(.regular)` when `showsDockIcon` (window
  mode or "Show Dock icon"), else `.accessory`.
- Login item: `SettingsStore.setLaunchAtLogin(_:)` uses `SMAppService.mainApp`. When the status is
  `.requiresApproval`, it opens `SMAppService.openSystemSettingsLoginItems()`.

## Keys

- ⌘K opens the command palette, ⌘F focuses the search field (both in `HeaderView`). ⌘1 to ⌘9 select a tab
  (`TabButton`). ⇧⌘O shows the Output panel (`OutputToggle`). ⌘Q quits (`FooterView`).
- Esc in `SearchField` clears the search (`.onExitCommand`). Esc in the palette closes the palette.

## Appearance

`preferredColorScheme` does not reach an `NSPanel`. `RootView` ends with `.background(WindowAppearance(name: .aqua))`
and `.colorScheme(.light)`; a pull request window sets `window.appearance = NSAppearance(named: .aqua)`. Never set
`NSApp.appearance`: the menu bar text would turn black on a dark menu bar.

## Hints

`HintCenter` (DevHubUI `Hint/`, `@Observable`) holds one `Hint(id:text:frame:)`. `PresentationAssembly` builds it and
`inject` puts it into `\.hintCenter`.

- `.hint(_:)` (`HintModifier`) reads its global frame with `onGeometryChange` and starts a task on hover. The delay
  is 550 ms, or 60 ms when a hint is visible or was hidden in the last 0.8 s. Hover end or `onDisappear` hides it.
- A local event monitor in `HintCenter` hides the hint on mouse down, key down and scroll.
- `HintOverlay` sits in an `.overlay` of `RootView`. It places `HintBubble` 6 pt below the item (above when there is
  no room), at least 8 pt from the edges, at most 260 pt wide (`CappedWidthLayout`), and shows it after it was
  measured.
- `.hintWhenTruncated(_:)` (`TruncationHintModifier`) shows the full text only when the text is cut.

## Check without a screen

```sh
APP="$(Scripts/build.sh | tail -1)"
DEVHUB_OPEN_PANEL=1 DEVHUB_TAB=git DEVHUB_SNAPSHOT=/tmp/panel.png "$APP/Contents/MacOS/DevHub"
```

`DebugLaunch` (DevHubComposition, Debug builds only) opens the panel 0.5 s after launch and writes the PNG after
`DEVHUB_SNAPSHOT_DELAY` more seconds (default 1). `AppWindows+Debug.swift` holds `debugShowPanel()` and
`debugSnapshot(to:)`. The full list of switches is in `build-and-run`. `screencapture` needs the Screen Recording
permission, so use the snapshot.

## Traps

- Alerts and sheets in the panel are unreliable. Confirm inline (`InlineConfirmation`).
- `.help` tooltips are slow in the panel. Use `.hint`.
- A snapshot does not show the status item, a context menu or a covered panel. `cacheDisplay` does not draw some
  controls (a prominent button can look empty). Check such results with tests or in a real run.
- A rebuilt ad-hoc binary can lose the Accessibility permission. Settings → Doctor shows it.
- Two menu bar icons mean two running copies. `Scripts/run.sh` stops only the copy built from this repository.
- A `Menu` with a custom label shows only its first text. Use a `Button` with a `.popover` for a rich label
  (`ProjectMenu`).
