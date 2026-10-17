import SwiftUI
import DevHubDomain
import DevHubUI

struct SearchFilterBar: View {
    @Environment(ProjectSession.self) private var session

    var body: some View {
        let query = session.searchText.trimmingCharacters(in: .whitespaces)
        if query.isEmpty == false {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .foregroundStyle(Color.accentColor)
                Text("Showing only items that match “\(query)”")
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("Clear search") {
                    session.searchText = ""
                }
                .buttonStyle(LinkButtonStyle(.accent, weight: .medium))
                .fixedSize()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(Color.accentColor.opacity(0.08))
            Divider()
        }
    }
}
