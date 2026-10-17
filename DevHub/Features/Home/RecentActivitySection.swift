import SwiftUI

struct RecentActivitySection: View {
    @Environment(ActivityLog.self) private var activity
    @Environment(ProjectSession.self) private var session

    private var events: [ActivityEvent] {
        activity.events
            .filter { session.matchesSearch($0.title, $0.detail) }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Recent") {
                Button("Clear") { activity.clear() }
                    .disabled(activity.events.isEmpty)
            }
            PanelCard {
                if events.isEmpty {
                    Text(activity.events.isEmpty ? "No activity yet." : "No activity matches the search.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(events) { event in
                            ActivityRow(event: event)
                            if event.id != events.last?.id {
                                Divider().padding(.leading, 18)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    RecentActivitySection()
        .padding()
        .previewEnvironment()
}
