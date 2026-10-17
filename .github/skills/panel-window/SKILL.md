---
name: panel-window
description: "How DevHub's menu bar item, panel and pinned window work: NSStatusItem plus an own NSPanel instead of MenuBarExtra, open and close rules, saved position and size, drag and resize, screen clamping, light appearance, hints overlay, global hot key, Dock icon and login item. Load before changing anything in DevHub/Shell, WindowLayout, hints or the status item."
---

# Panel Window

## Why not `MenuBarExtra`

`MenuBarExtra(.window)` puts its panel back under the icon on every open and every resize, and the panel cannot be moved. DevHub draws its own menu bar item and panel. The SwiftUI `App` body is `Settings { EmptyView() }`; `AppDependencies.live()` creates `AppWindows`, which owns the status item, the panel and the pinned window.

## Pieces

| Type | Role |
|---|---|
| `AppWindows` (Shell, split in `AppWindows+StatusItem`, `+Pinned`, `+Observation`) | status item button (left click toggles, right click shows a menu), panel, pinned window, click monitor, resign observer, layout and settings observation, hot key. Created with `AppWindows(layout:settings:navigator:session:makeContent:)`; `makeContent` receives a `PanelActions` and returns the root view as `AnyView`, so Shell never imports `AppDependencies` |
| `PanelActions` (Shell, environment `\.panelActions`) | `isPinned`, `togglePin`, `handleEscape`, `resetPosition`: how views talk to `AppWindows` without knowing it; defaults are no-ops so previews work |
| `MenuBarPanel: NSPanel` | borderless, `canBecomeKey` true, `isFloatingPanel`, `level = .statusBar`, `hidesOnDeactivate = false`, `isReleasedWhenClosed = false`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `animationBehavior = .none`, `isMovable = false`, clear background; the root view clips itself with a 10 pt rounded rectangle and the panel has a shadow |
| `WindowLayout` (Shared, `@Observable`, Foundation and CoreGraphics only) | `size`, `panelTopLeft`, `openCount`; `panelFrame(anchor:visibleFrames:)`, `resize(to:topLeft:visibleFrame:)`, `savePanelTopLeft`, `setSize`, `reset()`, `resetPosition()`; persisted through `AppPreferences` (`window.size`, `window.panelTopLeft`). The top-left point uses AppKit screen coordinates (y is the top edge). `AppWindows` re-fits the panel when `size` or `panelTopLeft` change |
| `WindowDragArea` (Shell, `NSViewRepresentable`) | moves the window itself in `mouseDragged` (`mouseDownCanMoveWindow` false), clamps to the usable area, reports the new top-left on mouse up; double-click resets to the icon |
| `ResizeGrip` (Shell) | drag changes `layout.size`; double-click resets to 720 × 820 |
| `WindowAppearance` (UI, `NSViewRepresentable`) | sets `window.appearance = NSAppearance(named: .aqua)` from inside the view tree |
| `HostWindowReader` | gives a view its `NSWindow` |
| `GlobalHotKey` (Services/Workspace) | Carbon `RegisterEventHotKey`, no Accessibility needed |

## Open and close

- First open creates the `NSHostingController` with `RootView().inject(dependencies)` and keeps it. Later opens only set the frame and `makeKeyAndOrderFront`, then `layout.openCount += 1`. `RootView` uses `.task(id: layout.openCount)` to refresh stores on each open and `.id("\(tab)#\(openCount)")` on the feature view.
- `NSApp.activate()` before `makeKeyAndOrderFront`, `statusItem.button?.highlight(true)` while open.
- Close on: a global mouse-down monitor (`NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown])`), `NSApplication.didResignActiveNotification`, Esc with an empty search field. Remove the monitor on close.

## Position and size

- The anchor is the status item button frame converted to screen coordinates: `x = midX - width / 2`, `y = minY - 4`. A saved `panelTopLeft` wins over the anchor.
- `panelFrame` picks the screen that contains the top-left point (else the anchor screen, else main), takes `visibleFrame` inset by 12, clamps the size to that area (and writes the clamped size back), clamps the point, writes the clamped point back when a saved point moved, and returns the frame.
- `AppWindows.fitPanel()` re-applies the frame when the layout changes (observed with `withObservationTracking`, re-armed after each change). When `panelTopLeft` becomes nil (double-click), the frame goes back to the icon. Screens are matched by x position only, because the menu bar is outside `visibleFrame`.
- `resize(to:topLeft:visibleFrame:)` limits the size to the room between the window's top-left corner and the screen edge, so resizing stops at the edge and the grip stays reachable.
- A display change (`NSApplication.didChangeScreenParametersNotification`) calls `fit`.

## Pinned window

`NSWindow` with `[.titled, .closable, .miniaturizable, .resizable]`, `level = .floating`, `isReleasedWhenClosed = false`, `contentMinSize = 640 × 560`, `setFrameAutosaveName("DevHubPinnedWindow")`. The same `RootView` with `.environment(\.isPinnedWindow, true)`. `NSHostingController.sizingOptions = [.minSize]`. In the pinned window the root view uses `frame(minWidth:idealWidth:maxWidth:…)` and reports its size back to `layout`; in the panel it uses a fixed `frame(width:height:)`.

## Appearance

`preferredColorScheme` does not reach the panel. `RootView` has `.background(WindowAppearance(name: .aqua))` and `.colorScheme(.light)`. Never `NSApp.appearance = …`: the menu bar label would turn black on a dark menu bar.

## Hints

`HintCenter` (`@Observable`, in the environment) holds one `Hint(id, text, frame)`. `.hint(_:)` reports its global frame with `onGeometryChange`, starts a task on hover (0.55 s, or 0.06 s when a hint was shown in the last 0.8 s) and shows the hint; hover end or `onDisappear` hides it. A local event monitor for mouse down, key down and scroll hides the current hint. `HintOverlay` sits in an `.overlay` of `RootView`, converts the frame into its own space, places the bubble 6 pt below the item (above when there is no room), 8 pt from the edges, at most 260 pt wide, and fades it in after the bubble was measured. `hintWhenTruncated` compares the ideal width (a hidden `fixedSize()` copy) with the real width.

## Hot key, Dock icon, login item

- `GlobalHotKey.register(shortcut)` unregisters the old key and registers the new one with `EventHotKeyID(signature: fourCharCode, id: 1)` on `GetApplicationEventTarget()`. The C handler posts a `Notification` on the main queue; the Swift side calls `AppWindows.showPinnedOrPanel()`. Fixed list: ⌥⌘D, ⌃⌥Space, ⌃⌥D, Off.
- Dock icon: `NSApp.setActivationPolicy(.regular)` or `.accessory`.
- Login item: `SMAppService.mainApp.register()` / `unregister()`; `status == .requiresApproval` → `SMAppService.openSystemSettingsLoginItems()` and a message.

## Escape key

`SearchField` handles Esc itself (`.onKeyPress(.escape)`) and `MenuBarPanel.cancelOperation` handles it when another view has focus. Both call `PanelActions.handleEscape`: clear the search, else close the panel.

## Check without a screen

`DEVHUB_OPEN_PANEL=1 DEVHUB_TAB=<id> DEVHUB_SNAPSHOT=<png path> <app>/Contents/MacOS/DevHub` opens the panel at launch and writes a picture of its content after 1.5 s (`App/DebugLaunch.swift`). Read the PNG to check a layout. `DEVHUB_RUN_TEST_COMMANDS=1` also runs the Home test commands. `screencapture` does not work without Screen Recording permission.

## Traps

- Alerts and sheets inside the panel are unreliable. Inline confirmation only.
- `.help` tooltips are slow in the panel. Use `.hint`.
- A rebuilt ad-hoc binary may lose Accessibility; show the path to System Settings instead of failing silently.
- Two menu bar icons mean two instances: `pkill -x DevHub`.
- A `Menu` with a custom label shows only its first text: use a `Button` with a `.popover` for a rich label (`ProjectMenu`).
