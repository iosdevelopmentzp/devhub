---
name: ui-components
description: "Reference for DevHub's shared SwiftUI building blocks (Tag, IconTile, IconButton, OverflowMenu, PanelCard, SectionHeader, SearchField, StatusDot, ActionBar, FlowLayout, SearchablePicker, InlineConfirm, KeyValueBlock, hints, copy on click), the row pattern with hover actions and inline confirmation, spacing and colour rules. Load before building or changing any UI."
---

# UI Components

All shared blocks live in `DevHub/UI/` (one view per file in `UI/Components/`, hints in `UI/Hint/`). Check this list before writing a new element. A new shared block goes into `UI/` and into this table.

## Components

| Component | Signature | Use for |
|---|---|---|
| `Tag` | `Tag("clean", tint: .green, systemImage: "checkmark")` | Status capsule, `.fixedSize()` by itself |
| `IconTile` | `IconTile(systemImage: "folder", tint: .blue, size: 32)` | Rounded square icon at the start of a row or card. 28 grid tile, 32 row, 36 card header |
| `IconButton` | `IconButton(systemImage: "trash", help: "Delete", tint: .red) { }` | 24 × 24 icon action with hover background and hint |
| `OverflowMenu` | `OverflowMenu { Button("Copy", systemImage: "doc.on.doc") { } }` | Ellipsis menu with the same 24 × 24 footprint |
| `PanelCard` | `PanelCard { VStack { } }` | White rounded surface, 12 padding, hairline border, soft shadow |
| `SectionHeader` | `SectionHeader("Recent") { Button("Clear") { } }` | Uppercase caption title with an optional trailing control |
| `SearchField` | `SearchField(prompt:text:focus:onEscape:)`, `focus` is a `FocusState<Bool>.Binding` | Header search; one per app, in `HeaderView` |
| `StatusDot` | `StatusDot(color: .green)` | 7 pt dot |
| `ActionBar` | `ActionBar(items: [ActionItem("Push", systemImage: "arrow.up", hint: "git push", priority: 6, isDisabled: false) { }])` (up to four steps of collapsing, lowest priority first) | A row of labelled buttons that never truncates: the lowest `priority` buttons drop their title first and keep the icon with the title in the hint (`ViewThatFits`) |
| `FlowLayout` | `FlowLayout(spacing: 6, lineSpacing: 4) { Tag(…) }` | Tags or short facts that wrap instead of being cut |
| `SearchablePicker` | `SearchablePicker(title: "Scheme", selection: $scheme, items: schemes) { _ in nil }` (strings) or `SearchablePicker(title:selection:items:label:detail:)` (any `Hashable`) | Any picker with more than six items: a button with the value, a popover with a search field and a list; arrows and Return select, Esc closes; 200 rows cap with "N more". `.trigger { item in AnyView(…) }` replaces the button label (the header project switcher uses it) |
| `InlineConfirm` | `InlineConfirm(text:confirmTitle:tint:onCancel:onConfirm:)` | The confirmation block inside a row |
| `KeyValueBlock` | `KeyValueBlock(pairs: [("Version", "1.2")])` | Two-column facts, used by the script `view` directive |
| `InlineError` | `InlineError(text:retry:)` | Error line with Retry |
| `SampleDataBanner` | `SampleDataBanner()` | Thin yellow bar on top of a screen that still shows mock data. Remove it when the screen gets a live provider |
| `ToastOverlay` | in `RootView` | Shows `Toaster.current` (green check, red cross for failures) |
| `EmptyState` | `EmptyState(systemImage:title:text:)` | Centered icon, title and one hint sentence |

The usage strip (`Features/Usage/`) has its own bar views (`UsageMeterBar`, `UsageProviderRow`); they are feature views, not shared blocks. `SampleDataBanner` is now unused: every screen except Build has live data.

Tints come from `Core.Tint` (`gray red orange yellow green teal blue indigo purple pink`) and map to `Color` in `UI/Theme.swift`.

## Hints and truncation

Every icon without visible text explains itself on hover. `IconButton(help:)` and `OverflowMenu` do it already. Anything else gets `.hint("…")`: a dark bubble under the element after 0.55 s, 0.06 s while moving between elements. Never `.help`: the system tooltip is slow and unreliable in a menu bar panel. A hint says what happens, plus the git or simctl command when there is one.

Nothing a user acts on may be cut:
- Labelled buttons get `.fixedSize()`. A toolbar with more than three labelled buttons uses `ActionBar`.
- Several tags in a row that can grow go into `FlowLayout`.
- Text may truncate (`lineLimit(1)`, `.truncationMode(.middle)` for names and paths) but then shows the full text on hover: `.hintWhenTruncated(text)`. `copyOnClick` does this already and adds "Click to copy".
- In a row the info column takes `.frame(maxWidth: .infinity, alignment: .leading)`; the action buttons keep their size.

## Copy and toast

Static text a user may paste (path, branch, hash, UDID, command) gets `.copyOnClick(value, label:)` (it needs `Toaster` in the environment, optional): pointer cursor, underline on hover, click copies and shows "Copied: …". Copy buttons and menu items call `toaster.copy(value, label:)`. Not on text inside a row whose own tap selects the row.

## Row pattern

```swift
HStack(spacing: 10) {
    IconTile(systemImage: "…", tint: …, size: 32)
    VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 6) {
            Text(title).font(.callout.weight(.semibold)).lineLimit(1)
            Tag("current", tint: .blue)
        }
        Text(path).font(.caption.monospaced()).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
        FlowLayout(spacing: 6, lineSpacing: 4) { /* tags, caption2 secondary details */ }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    HStack(spacing: 2) {
        IconButton(…) { }
        OverflowMenu { … }
    }
    .opacity(isHovered || isSelected ? 1 : 0)
}
.padding(.horizontal, 14)
.padding(.vertical, 8)
.background(isSelected ? Color.accentColor.opacity(0.08) : isHovered ? Theme.hover : .clear)
.contentShape(Rectangle())
.onHover { isHovered = $0 }
.contextMenu { /* the same actions */ }
```

Rules:
- Actions are always in the tree and toggle `opacity`. Never insert or remove views on hover; the text would jump.
- Dividers between rows: `Divider().padding(.leading, 56)`.
- Keyboard: the list owns `@FocusState`; arrows move the selection, Return runs the primary action (P2).

## Inline confirmation

No `.alert`, no `.confirmationDialog`. The row grows by one line:

```swift
if isConfirmingDelete {
    InlineConfirm(
        text: "Delete this worktree? 7 uncommitted changes will be lost.",
        confirmTitle: "Delete",
        tint: .red,
        onCancel: { confirmingID = nil },
        onConfirm: { store.delete(id: item.id) }
    )
}
```

The parent owns `@State private var confirmingID: Item.ID?` and animates with `.animation(.snappy(duration: 0.18), value: confirmingID)`. The text names the consequence.

## Screen skeleton

```
VStack(spacing: 0) {
    toolbar row   .controlSize(.small) .padding(.horizontal, 14) .padding(.vertical, 8) .background(Theme.base)
    Divider()
    ScrollView { LazyVStack(spacing: 0) { rows } .padding(.vertical, 4) }   or   EmptyState / ContentUnavailableView.search
}
.background(Theme.surface)
```

Hints, copy and toasts read `HintCenter` and `Toaster` as optional environment values, so a component preview works without `previewEnvironment()`; use `.previewEnvironment()` when hints or toasts matter.

Card screens (Home) use `ScrollView { VStack(alignment: .leading, spacing: 18) { … } .padding(14) }` on `Theme.base`.

## Spacing and type

| Token | Value |
|---|---|
| Screen horizontal padding | 14 |
| Row vertical padding | 7 (dense) or 8 |
| Divider inset | 56 |
| Card padding | 12 |
| Grid gap | 8; four columns at 720 pt, fewer when narrower (`LazyVGrid` with `.adaptive(minimum: 160)`) |
| Corner radius | 10 cards and tiles, 8 inline bars, 7 tab buttons, 6 icon button hover |
| Row title | `.callout.weight(.semibold)` |
| Secondary line | `.caption` `.secondary`; paths and names `.monospaced()` |
| Detail line | `.caption2` `.secondary` |
| Section title | `.caption.weight(.semibold)` uppercase, kerning 0.6 |

## Colour

Light scheme forced in `RootView` by `WindowAppearance(name: .aqua)` plus `.colorScheme(.light)`. Never set `NSApp.appearance`. Tokens in `DevHub/UI/Theme.swift`:

| Token | Use |
|---|---|
| `Theme.base` | chrome: usage strip, header, tab bar, toolbars, footer, Home background (near-white) |
| `Theme.surface` | cards, list areas, fields (white) |
| `Theme.border` | hairline stroke |
| `Theme.hover` | row, tile and button hover |
| `Theme.shadow` | card shadow, radius 3, y 1 |

Selection: tab pill `Color.accentColor` with white text, selected row accent at 0.08, hovered tile border accent at 0.5.

Semantic tints: green clean, success, booted; orange changes, booting, fast build; red missing, failure, destructive; blue current, target, branch; purple merged, scripts; indigo project; `.secondary` neutral.

## Previews

Every screen file ends with:

```swift
#Preview {
    XView()
        .previewEnvironment()
}
```

`previewEnvironment()` injects `AppDependencies.mock()` and the 720 × 820 frame.
