import SwiftUI
import DevHubDomain
import DevHubUI

struct HeaderView: View {
    @Environment(Navigator.self) private var navigator
    @Environment(AppActions.self) private var appActions
    @Environment(SettingsStore.self) private var settings
    @Environment(ActivityLog.self) private var activity
    @Environment(InboxStore.self) private var inbox
    @Environment(\.isPinnedWindow) private var isPinnedWindow
    @Environment(\.togglePin) private var togglePin

    private var badgeCount: Int {
        activity.unreadCount + inbox.unreadCount
    }

    var body: some View {
        HStack(spacing: 10) {
            ProjectMenu()
            Spacer(minLength: 8)
            IconButton(systemImage: "command", help: "Command palette (⌘K): tabs, actions, branches, simulators, worktrees, requests, sessions") {
                navigator.togglePalette()
            }
            .keyboardShortcut("k", modifiers: .command)
            if settings.values.windowMode == .panel {
                IconButton(
                    systemImage: isPinnedWindow ? "pin.fill" : "pin",
                    help: isPinnedWindow ? "Unpin: close this window, use the menu bar panel" : "Pin: keep DevHub open in a floating window",
                    tint: isPinnedWindow ? .accentColor : .primary
                ) {
                    togglePin()
                }
            }
            IconButton(
                systemImage: badgeCount > 0 ? "bell.badge" : "bell",
                help: "Notifications: the events of the last 30 days and the Inbox",
                tint: navigator.selection == .feature(.notifications) ? .accentColor : .primary
            ) {
                appActions.openNotifications()
            }
            .overlay(alignment: .topTrailing) {
                if badgeCount > 0 {
                    Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                        .font(.system(size: 9, weight: .bold).monospacedDigit())
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.accentColor, in: Capsule())
                        .foregroundStyle(Color.white)
                        .fixedSize()
                        .offset(x: 8, y: -5)
                        .allowsHitTesting(false)
                }
            }
            IconButton(
                systemImage: "gearshape",
                help: "Settings",
                tint: navigator.selection == .feature(.settings) ? .accentColor : .primary
            ) {
                appActions.openSettings()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(PanelDragArea())
    }

}
