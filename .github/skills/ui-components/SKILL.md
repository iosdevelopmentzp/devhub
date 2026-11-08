---
name: ui-components
description: "Reference for DevHub's shared SwiftUI blocks in the DevHubUI module (RowContainer, InlineConfirmation, ListState, ListMessage, ListSectionHeader, ToolbarBar, Tag, ModelTag, TagModel, PlainTag, IconTile, IconButton, OverflowMenu, HoverActions, ActionBar, PanelCard, SectionHeader, SearchField, SearchablePicker, NoticeBar, FlowLayout, KeyValueBlock and more), Theme and Tint, the formatters, hints and copy on click, the row model and mapper pattern with hover actions and inline confirmation, spacing and colour rules. Load before building or changing any UI."
---

# UI Components

Shared blocks live in `Packages/DevHubKit/Sources/DevHubUI/`, one component per file, hints in `Hint/`, formatters
in `Formatters/`. DevHubUI imports no DevHub module. Every component is `package`, with `package init` and
`package var body`. A view that needs a Domain value gets plain values instead. Check this list before you write a
new element. A new shared block goes into DevHubUI and into this table.

## Components

| Component | Example | Use for |
|---|---|---|
| `RowContainer` | `RowContainer(isHighlighted: model.isSelected) { isHovered in … }` | Every list row: padding 14 × 8 (`verticalPadding:`), hover background `Theme.hover`, highlight colour, hit shape. Passes `isHovered` to the content |
| `InlineConfirmation` | `InlineConfirmation("Delete worktree?", confirmTitle: "Delete", confirmRole: .destructive, layout: .stacked(warnings: model.deleteWarnings), onCancel: …, onConfirm: …) { Toggle(…) }` | The confirmation block inside a row. `.line` or `.stacked(warnings:)`; optional `details` and `extra` builders; `tint:` (default red) |
| `ListState` | `ListState(failure:isLoading:loadingTitle:empty:noResultsFor:) { list }` | The states of a list in a fixed order: failure, loading, empty, no search results, content |
| `ListMessage` | `ListMessage("No AI sessions", systemImage: "…", description: "…")`, `ListMessage.failure("Cannot read worktrees", description: error) { retry }` | The text of an empty or failure state, with an optional button |
| `ListSectionHeader` | `ListSectionHeader("Staged 2") { Button("Unstage All") {}.buttonStyle(LinkButtonStyle(.accent)) }` | A caption header inside a list, padding 14 |
| `SectionHeader` | `SectionHeader("Recent") { … }` | An uppercase caption title (kerning 0.6) on card screens such as Home |
| `ToolbarBar` | `ToolbarBar { HStack { … } }` | The bar on top of a tab: small controls, padding 14 × 8, `Theme.base` |
| `Tag` | `Tag("clean", tint: .green, systemImage: "checkmark")` | A status capsule. Fixed size, never cut |
| `ModelTag`, `TagModel` | `ModelTag(model: TagModel("3 changed", tint: .orange, hint: "Uncommitted changes"))`, `TagModel.icon("checkmark.circle.fill", tint: .green, hint: "Passed")` | A tag from a row model, with its hint. `isPlain: true` draws a `PlainTag` |
| `PlainTag` | `PlainTag("approved", systemImage: "checkmark.seal")` | Icon and caption text without a capsule |
| `IconTile` | `IconTile(systemImage: model.icon, tint: model.iconTint.color, size: 32)` | The rounded icon square at the start of a row (32) or a card |
| `IconButton` | `IconButton(systemImage: "trash", help: "Delete worktree", tint: .red) { … }` | A 24 × 24 icon action with hover background and a hint. `IconButton.side` is 24 |
| `ToggleIconButton` | `ToggleIconButton(systemImage: "text.justify.leading", help: model.fullHint, isOn: model.isFull) { … }` | An `IconButton` for a mode that stays on: accent icon and accent background while `isOn`, dimmed when disabled. The hint says what the next click does |
| `OverflowMenu` | `OverflowMenu { Button("Copy Path", systemImage: "doc.on.doc") { … } }` | The ellipsis menu, same 24 × 24 size, hint "More actions" |
| `HoverActions` | `HoverActions(isVisible: isHovered, count: 3, spacing: 2) { IconButton(…) }` | Hover buttons that keep their width when hidden (an empty frame of `count` buttons) |
| `ActionBar`, `ActionItem` | `ActionBar(items: [ActionItem("Push", systemImage: "arrow.up", hint: "git push", priority: 6, isDisabled: false) { … }])` | A row of labelled buttons that never cuts a title: the lowest `priority` buttons lose their title first (`ActionBarLayout`, `ActionBarFit`) |
| `PanelCard` | `PanelCard { VStack { … } }` | A white card: padding 12, corner 10, hairline border, soft shadow |
| `SearchField` | `SearchField(prompt: "Search worktrees", text: $session.searchText, focus: $isSearchFocused)` | The search field. `TabSearchField` (Presentation `Shell/`) wraps it with the prompt of the tab, `ProjectSession.searchText` and ⌘F; each tab places `TabSearchField()` in its toolbar next to the list it filters |
| `SearchablePicker` | `SearchablePicker(title: "Scheme", selection: $scheme, items: schemes) { _ in nil }` or `(title:selection:items:label:detail:)` | A picker with a search field in a popover. Arrows and Return select, Esc closes, 200 rows at most. `.trigger { AnyView(…) }` replaces the button label |
| `NoticeBar` | `NoticeBar("Cannot read pull requests: …", actionTitle: "Retry") { … }` | A thin bar with an icon, a text and an optional button over a list that still shows old data |
| `RemovableChip` | `RemovableChip("target: dev", systemImage: "arrow.triangle.branch", removeHint: "Remove this filter") { … }` | An active filter chip with an x |
| `StatusDot` | `StatusDot(color: .green)` | A 7 pt dot |
| `FlowLayout` | `FlowLayout(spacing: 6) { ModelTag(…) }` | Tags or short facts that wrap instead of being cut. `lineSpacing:` default 6 |
| `KeyValueBlock` | `KeyValueBlock(pairs: [("Version", "1.2")])` | Two columns of facts, used by the script `view` directive |
| `FieldLabel` | `FieldLabel("Device ID")` | A caption label of fixed width 78 in front of a field |
| `LinkButtonStyle` | `.buttonStyle(LinkButtonStyle(.accent, weight: .medium))` | A text button in caption size, `.secondary` or `.accent` |
| `ExpandableText` | `ExpandableText(attributed, lineLimit: 5)` | Long text with "Show all" and "Show less" |
| `PlainTextEditor` | `PlainTextEditor(text: $payload)` | A monospaced plain `NSTextView` editor without smart quotes, dashes or spelling correction (JSON, payloads) |
| `SplitHandle` | `SplitHandle(axis: .vertical, onDrag: { … }, onEnd: { … })` | A drag handle between two panes: `.vertical` between left and right (the pull request list), `.horizontal` between top and bottom (the Output panel edge). `onDrag` gets the translation along the drag axis |
| `ToastView` | in `RootView` | Shows `Toaster.text` at the bottom of the tab |
| `FolderPicker` | `FolderPicker.chooseFolder(directory:prompt:message:)`, `chooseFile(…)`, `chooseFiles(directory:prompt:message:extensions:)` (several files of the given extensions, `[URL]`), `saveFile(suggestedName:prompt:message:)` | `NSOpenPanel` or `NSSavePanel` that returns a `URL?` |
| `WindowAppearance`, `HostWindowReader` | `.background(WindowAppearance(name: .aqua))` | Window appearance and window access from the view tree (`panel-window`) |
| `FileImage` | `FileImage(path: attachment.path, maxHeight: 120)` | An image file from disk, fitted, with a hairline border; "Image not found" when the file cannot be read. Used for the test attachments |
| `FileDropView` | `FileDropView(accepts:onTarget:onDrop:onClick:)` added to `statusItem.button` | An AppKit view that takes file drops and passes mouse down to `onClick`; used on the menu bar icon (`panel-window`) |

Feature views that look shared are not shared blocks: the usage bars (`Features/Usage/`), `ConfigActionBar` and
`ConfigActionMenuItems` (`Features/ConfigActions/`), `LaunchPicker` (`Features/Build/`), `OperationsTray`,
`OperationCard` and `OperationsIndicator` (`Features/Operations/`). They live in DevHubPresentation because they read
stores or Domain types.

A place that runs commands for the user starts an operation (`ActionRunner` or `OperationLog.start`) instead of a busy
title alone. Its card shows in the `OperationsTray` at the bottom of the tab (`RootView` overlay): steps, the failure
digest, Retry, Copy Error, Full Output. Nothing is placed inline, so the content never jumps.

## Theme and Tint

`Theme` (`Theme.swift`) holds the only colour constants:

| Token | Use |
|---|---|
| `Theme.base` | chrome: header, tab bar, toolbars, footer, Home background (near white) |
| `Theme.surface` | lists, cards, fields (white) |
| `Theme.border` | hairline stroke |
| `Theme.hover` | row, tile and button hover |
| `Theme.shadow` | card shadow, radius 3, y 1 |

`Tint` (`Tint.swift`) is the colour choice in a row model: `green orange yellow red blue purple indigo teal pink gray
secondary`. `Tint+Color.swift` maps it with `tint.color`. A mapper chooses a `Tint`; the view calls `.color`. A colour
from `.devhub` config goes through `ConfigTintMapper` (Presentation). No hex values outside `Theme`.

Meaning of the tints: green clean, success, booted; orange changes, booting; red missing, failure, destructive; blue
current, target, branch; purple merged, scripts; indigo project; `.secondary` neutral.

Selection: the selected tab is `Color.accentColor` with white text; a selected or highlighted row is accent at 0.08
(`RowContainer` default).

## Formatters

`Formatters/` holds every text format a mapper needs. No `DateFormatter` in a view or a mapper.

| Formatter | Output |
|---|---|
| `date.relativeDescription` (`Date+RelativeDescription`) | "2 hr. ago" |
| `ByteFormat.text(_:)` | "1.2 GB" |
| `CountText.count(_:_:_:)`, `CountText.invariant(_:_:)` | "3 changes", "1 change" |
| `DurationFormat.text(_:)` | "850 ms", "4.2 s", "1 m 12 s" |
| `SyncText.text(ahead:behind:)`, `ahead(_:)`, `behind(_:)` | "↑2 ↓1" |
| `LogTimestamp.text(_:)` | "14:05:09.123", the time of a log line |
| `ClockTime.text(_:)` | "14:05:09", the start time of a command |
| `Countdown.text(_:)` | "2h 5m", the time until a usage limit resets |
| `DayLabel.text(for:now:calendar:)` | "Today", "Yesterday", else the short date, for a section header by day |
| `ElapsedTime.text(_:)` | "1:20", "12:05", "1:02:03", the time since an update started |

Tests never assert on the exact text of locale or clock formatters, only nil or not empty.

## Hints and truncation

Every icon without visible text explains itself on hover. `IconButton(help:)`, `ToggleIconButton(help:)`,
`OverflowMenu` and `ModelTag` (with `TagModel.hint`) do it already. A window that does not show `RootView` (the
request window) draws its own hints: its root gets `.hintHost(HintCenter())` before `inject`. Anything else gets `.hint("…")`. Never `.help`: the system tooltip is slow and
unreliable in a menu bar panel. A hint says what happens, plus the git or simctl command when there is one. Timing and
placement: `panel-window`.

Nothing a user acts on may be cut:

- A labelled button gets `.fixedSize()`. A bar with more than three labelled buttons uses `ActionBar`.
- Tags that can grow go into `FlowLayout`.
- Text may truncate (`.lineLimit(1)`, `.truncationMode(.middle)` for names and paths), then it shows the full text on
  hover with `.hintWhenTruncated(text)`.
- In a row the info column takes the free width; the action buttons keep their size.

## Copy and toast

Text a user may paste (path, branch, hash, UDID, command) gets `.copyOnClick(value, label:)`: pointer cursor,
underline on hover, the full text in a hint with "Click to copy". It calls `\.copyToPasteboard`, which `inject` sets to
`Toaster.copy(_:label:)`, so DevHubUI needs no `Toaster`. Copy buttons and menu items call
`toaster.copy(value, label:)` or `copyToPasteboard(value, label)` in their own action. `.copyOnClick` on a menu item
does nothing, so a menu item copies in its own action. `Toaster.copy` writes through `PasteboardWriter`, the only file with `NSPasteboard`.
Not on text inside a row whose own tap selects the row.

## Row model and mapper

A row draws one model. The mapper chooses every text, icon, tint, hint and enabled flag. The view chooses only
constant styling.

```swift
struct AISessionRowModel: Identifiable, Equatable {
    let id: AISession.ID
    var title: String
    var icon: String
    var iconTint: Tint
    var providerTag: TagModel
    var statusTags: [TagModel]
    var canResume: Bool
    var resumeHint: String

    static let preview = AISessionRowModel(…)
}

enum AISessionRowMapper {
    static func model(for item: AISession) -> AISessionRowModel {
        AISessionRowModel(
            id: item.id,
            title: item.title,
            icon: icon(for: item.provider),
            iconTint: item.folderExists ? .orange : .secondary,
            providerTag: TagModel(title(for: item.provider), tint: .secondary),
            statusTags: item.folderExists ? [] : [TagModel("folder missing", tint: .red, systemImage: "folder.badge.questionmark")],
            …
        )
    }
}
```

Files: `Features/<Name>/Models/<Row>Model.swift` and `<Row>Mapper.swift`. Tests: `<Row>MapperTests` in
`DevHubPresentationTests/Mappers/<Name>/` and one line in `ModelPreviewsTests`.

## Row pattern

From `WorktreeRow`, shortened:

```swift
var body: some View {
    RowContainer(isHighlighted: model.isHighlighted) { isHovered in
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                IconTile(systemImage: model.icon, tint: model.iconTint.color, size: 32)
                    .hint(model.iconHint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.title)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(model.displayPath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .copyOnClick(model.path, label: model.pathCopyLabel)
                    FlowLayout(spacing: 6) {
                        ForEach(model.statusTags, id: \.self) { ModelTag(model: $0) }
                    }
                }
                Spacer(minLength: 4)
                HStack(spacing: 2) {
                    IconButton(systemImage: "folder", help: "Open in Finder") { appActions.openInFinder(path: model.path) }
                    IconButton(systemImage: "trash", help: "Delete worktree", tint: model.deleteTint.color) { onRequestDelete() }
                        .disabled(model.canDelete == false)
                }
                .opacity(isHovered && isConfirmingDelete == false ? 1 : 0)
            }
            if isConfirmingDelete {
                deleteConfirmation
            }
        }
    }
    .contextMenu { contextMenu }
}
```

Rules:

- Hover actions stay in the tree and change `opacity`, or sit in `HoverActions`. The row never changes its layout on
  hover.
- The same actions are in `.contextMenu`, plus copy items and `ConfigActionMenuItems(items:onRun:)` for `.devhub`
  actions.
- A row reads `Toaster` and `AppActions` at most. Everything else comes as a model or a closure.
- Dividers between rows: `Divider().padding(.leading, 56)`.
- `@State` in a row only for confirmation or editing input. Hover comes from `RowContainer`.

## Inline confirmation

No `.alert`, no `.confirmationDialog`, no sheet. The row grows by a block. The screen owns the state and animates it:

```swift
@State private var confirmingDeleteID: Worktree.ID?

.animation(.snappy(duration: 0.18), value: confirmingDeleteID)
```

The row shows `InlineConfirmation` while `isConfirmingDelete` is true. The title names the consequence; warnings list
what will be lost.

## Screen skeleton

```swift
VStack(spacing: 0) {
    ToolbarBar { … }
    Divider()
    ListState(…) {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) { sections and rows }
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
.background(Theme.surface)
.task(id: openCount) { await store.refresh() }
```

Card screens (Home) use a `ScrollView` with a `VStack` of `PanelCard`s and `SectionHeader`s on `Theme.base`. The
quick actions grid is a `LazyVGrid` with four flexible columns.

## Spacing and type

| Token | Value |
|---|---|
| Horizontal padding of a screen, row or bar | 14 |
| Row vertical padding | 8 (`RowContainer` default), 7 for dense rows |
| Divider inset | 56 |
| Card padding | 12 |
| Corner radius | 10 cards and panel, 8 inline confirmation, 7 search field and tab buttons, 6 icon button hover |
| Row title | `.callout.weight(.semibold)` or `.weight(.medium)` |
| Secondary line | `.caption`, `.secondary`; paths, file names, hashes and commands `.monospaced()` |
| Detail line | `.caption2`, `.secondary` |
| Tag text | `.caption2.weight(.semibold)` |

The panel is 720 × 820 by default and at least 640 × 560. Layouts stretch: no fixed widths for rows or screens.

## Colour scheme

The light scheme is forced on every window: `RootView` ends with `.background(WindowAppearance(name: .aqua))` and
`.colorScheme(.light)`. Never set `NSApp.appearance`.

## Previews

Every screen file ends with:

```swift
#Preview {
    WorktreesView()
        .previewEnvironment()
}
```

Every row file ends with `#Preview { WorktreeRow(model: .preview, …).previewEnvironment() }`. `previewEnvironment()`
injects `PresentationAssembly.preview()` (mocks, `InMemoryKeyValueStore`, `MockData`) and a 720 × 820 frame. A
DevHubUI component preview needs no environment: `\.hintCenter` is optional and `\.copyToPasteboard` has a no-op
default.
