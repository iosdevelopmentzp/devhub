import SwiftUI
import DevHubDomain
import DevHubUI

struct NotificationsView: View {
    @Environment(ActivityLog.self) private var activity
    @Environment(ProjectSession.self) private var session
    @Environment(AppActions.self) private var appActions
    @Environment(\.codeHostWords) private var words
    @State private var filter: NotificationFilter = .all

    var body: some View {
        VStack(spacing: 0) {
            ToolbarBar {
                HStack(spacing: 10) {
                    Text(countText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    filterMenu
                    Button("Clear") {
                        activity.clear()
                    }
                    .buttonStyle(LinkButtonStyle(.secondary))
                    .disabled(activity.events.isEmpty)
                }
            }
            Divider()
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
        .background(Theme.surface)
        .onAppear {
            activity.markSeen()
        }
    }

    private var sections: [NotificationSectionModel] {
        NotificationListMapper.sections(events: activity.events, filter: filter, query: session.searchText, words: words, now: .now, calendar: .current)
    }

    private var countText: String {
        NotificationListMapper.countText(visible: sections.reduce(0) { $0 + $1.rows.count }, total: activity.events.count)
    }

    private var emptyMessage: ListMessage? {
        guard activity.events.isEmpty else { return nil }
        return ListMessage("No events yet", systemImage: "bell", description: "Builds, test runs, \(words.request) changes and script notifications of the last \(ActivityRetentionPolicy.days) days appear here.")
    }

    private var noResultsText: String? {
        guard activity.events.isEmpty == false, sections.isEmpty else { return nil }
        let trimmed = session.searchText.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? NotificationKindText.filterTitle(for: filter, words: words) : trimmed
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
