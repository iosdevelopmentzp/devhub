import SwiftUI
import DevHubDomain
import DevHubUI

struct NotificationsView: View {
    @Environment(ActivityLog.self) private var activity
    @Environment(InboxStore.self) private var inbox
    @Environment(ProjectSession.self) private var session
    @Environment(AppActions.self) private var appActions
    @Environment(\.codeHostWords) private var words
    @State private var filter: NotificationFilter = .all

    var body: some View {
        VStack(spacing: 0) {
            ToolbarBar {
                HStack(spacing: 10) {
                    panePicker
                    Text(countText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    TabSearchField()
                    if inbox.pane == .inbox {
                        inboxActions
                    } else {
                        eventActions
                    }
                }
            }
            Divider()
            if inbox.pane == .inbox {
                inboxList
            } else {
                eventList
            }
        }
        .background(Theme.surface)
        .onAppear {
            activity.markSeen()
        }
        .task(id: inbox.pane) {
            guard inbox.pane == .inbox else { return }
            await inbox.refreshIfStale()
        }
    }

    private var panePicker: some View {
        Picker("Show", selection: Binding(get: { inbox.pane }, set: { inbox.show($0) })) {
            Text("Events").tag(NotificationsPane.events)
            Text(inbox.unreadCount > 0 ? "Inbox \(inbox.unreadCount)" : "Inbox").tag(NotificationsPane.inbox)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .hint("Events: what DevHub did and noticed. Inbox: mentions, review requests, assignments and comments for you on \(words.name)")
    }

    private var eventActions: some View {
        HStack(spacing: 10) {
            filterMenu
            Button("Clear") {
                activity.clear()
            }
            .buttonStyle(LinkButtonStyle(.secondary))
            .disabled(activity.events.isEmpty)
        }
    }

    private var inboxActions: some View {
        HStack(spacing: 10) {
            Button("Mark All as Done") {
                inbox.markAllDone()
            }
            .buttonStyle(LinkButtonStyle(.secondary))
            .disabled(inbox.items.isEmpty)
            IconButton(systemImage: "arrow.clockwise", help: "Read the Inbox again") {
                Task { await inbox.refresh() }
            }
            .disabled(inbox.isLoading)
        }
    }

    private var eventList: some View {
        ListState(
            failure: nil,
            isLoading: false,
            loadingTitle: "",
            empty: emptyMessage,
            noResultsFor: noResultsText
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sections) { section in
                        ListSectionHeader(section.title) {}
                        ForEach(section.rows) { row in
                            ActivityRow(model: row) {
                                if let target = row.target {
                                    appActions.open(target)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            if row.id != section.rows.last?.id {
                                Divider()
                                    .padding(.leading, 29)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var inboxList: some View {
        ListState(
            failure: inbox.error.map { error in
                ListMessage.failure("Cannot read the Inbox of \(words.name)", description: error) {
                    Task { await inbox.refresh() }
                }
            },
            isLoading: inbox.isLoading && inbox.items.isEmpty,
            loadingTitle: "Reading the Inbox of \(words.name)…",
            empty: inboxEmptyMessage,
            noResultsFor: inboxNoResultsText
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(inboxRows) { row in
                        InboxRow(model: row) {
                            inbox.markDone(row.id)
                        }
                        if row.id != inboxRows.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sections: [NotificationSectionModel] {
        NotificationListMapper.sections(events: activity.events, filter: filter, query: session.searchText, words: words, now: .now, calendar: .current)
    }

    private var inboxRows: [InboxRowModel] {
        InboxRowMapper.models(for: inbox.items, busyIDs: inbox.busyIDs, query: session.searchText, words: words)
    }

    private var countText: String {
        guard inbox.pane == .events else {
            return NotificationListMapper.countText(visible: inboxRows.count, total: inbox.items.count, noun: "item")
        }
        return NotificationListMapper.countText(visible: sections.reduce(0) { $0 + $1.rows.count }, total: activity.events.count)
    }

    private var emptyMessage: ListMessage? {
        guard activity.events.isEmpty else { return nil }
        return ListMessage("No events yet", systemImage: "bell", description: "Builds, test runs, \(words.request) changes and script notifications of the last \(ActivityRetentionPolicy.days) days appear here.")
    }

    private var inboxEmptyMessage: ListMessage? {
        guard inbox.items.isEmpty, inbox.error == nil else { return nil }
        return ListMessage("Inbox is empty", systemImage: "tray", description: "Mentions, review requests, assignments and comments for you on \(words.name) appear here, for this repository.")
    }

    private var noResultsText: String? {
        guard activity.events.isEmpty == false, sections.isEmpty else { return nil }
        let trimmed = session.searchText.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? NotificationKindText.filterTitle(for: filter, words: words) : trimmed
    }

    private var inboxNoResultsText: String? {
        guard inbox.items.isEmpty == false, inboxRows.isEmpty else { return nil }
        return session.searchText.trimmingCharacters(in: .whitespaces)
    }

    private var filterMenu: some View {
        Menu {
            Picker("Show", selection: $filter) {
                Text("All").tag(NotificationFilter.all)
                ForEach(NotificationKind.allCases, id: \.self) { kind in
                    Text(NotificationKindText.title(for: kind, words: words)).tag(NotificationFilter.kind(kind))
                }
                Text("Other events").tag(NotificationFilter.other)
            }
            .pickerStyle(.inline)
        } label: {
            Image(systemName: filter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(filter == .all ? Color.secondary : Color.accentColor)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .hint(filter == .all ? "Filter by kind" : "Showing \(NotificationKindText.filterTitle(for: filter, words: words)). Click to change the filter")
    }
}

#Preview {
    NotificationsView()
        .previewEnvironment()
}
