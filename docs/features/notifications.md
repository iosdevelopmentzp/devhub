# Notifications

The bell in the header opens the Notifications screen: every event of the app from the last 30 days, newest first, grouped by day. The same events feed the macOS notifications and the Recent list on Home.

Code: `Packages/DevHubKit/Sources/DevHubPresentation/Features/Notifications/`, `Shared/ActivityLog.swift`, `Shared/Notifier.swift`, `DevHubDomain/Models/ActivityEvent.swift`, `ActivityTarget.swift`, `NotificationKind.swift`, `Policies/ActivityRetentionPolicy.swift`, `DevHubData/Workspace/SystemUserNotificationRepository.swift`.

## What it shows

- The bell in the header shows a badge with the number of events since the last time the screen was open (`ActivityLog.unreadCount`, saved as `activity.seenAt`). The screen marks everything as seen when it opens.
- A toolbar with the count ("12 events", or "3 of 12 events" with a filter), a filter menu and Clear.
- Sections by day: "Today", "Yesterday", then the date. Each row: a coloured dot (green success, red failure, grey info), the title, the detail, the time ("5 min. ago"), the kind ("Build", "Tests", "Review", "My PR" or "My MR", "Script") and an arrow button when the event has a place to open.
- The header search filters the rows by title and detail.

## Kinds

Every event that DevHub can also send as a macOS notification carries a kind. Events without a kind (a git action, a removed worktree, a copied value) show under "Other events" in the filter.

| Kind | Event | A click opens |
|---|---|---|
| Builds | a build or a launch finished, or the build failed | the run bar in the Simulators tab |
| Test runs | the tests of a worktree finished, did not run or were cancelled | the Worktrees tab |
| Pull Requests waiting for your review | the number of requests that wait for your review went up | the Pull Requests tab in the "To review" scope |
| Reviews of my pull requests | someone approved your request or asked for changes | the request |
| Checks of my pull requests | the checks or pipeline of your request turned to failed | the request |
| Comments on my pull requests | new comments on your request | the request |
| My pull requests merged or closed | your request was merged, or closed without a merge | the request |
| Script notifications | a script printed a `notify` line | nothing |

The words follow the host: "merge request" and "Pipeline" on GitLab.

## macOS notifications

- Settings → Notifications has the main switch "Notify while the panel is closed" and one switch per kind, each with a description ([Settings](settings.md#notifications)). A muted kind still goes to the list and to Recent.
- A kind other than the script one posts only while the panel and the pinned window are closed and the main switch is on. The script kind posts in every case, unless it is muted.
- A click on a macOS notification opens DevHub (the panel or the window, by the window mode) at the place of the event. A notification without a place opens the Notifications screen.
- The notification carries its place in `userInfo` (`NotificationTargetCodec`); `NotificationCenterDelegate` reads it back and hands it to `AppWindows` through `UserNotificationRepository.activations()`.

## Storage

- `ActivityLog` keeps the events in `app.recentEvents` (JSON in the defaults) and drops events older than 30 days and beyond 500 (`ActivityRetentionPolicy`).
- Clear removes every event, also from the store.

## Limits

- An event is per app, not per project: the list shows the events of every project.
- The place of an event is not checked when you click: a request that was merged still opens the Pull Requests tab and reveals nothing when it is no longer in the list.
- The bell badge and the arrow buttons were checked by tests and headless snapshots, not by clicks.
