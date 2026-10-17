import SwiftUI

struct SearchFilterBar: View {
    @Environment(ProjectSession.self) private var session

    var body: some View {
        if session.isSearching {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(Color.accentColor)
                Text("Filtered by “\(session.searchText)”")
                    .font(.caption)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Clear search") { session.searchText = "" }
                    .controlSize(.small)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(Color.accentColor.opacity(0.1))
        }
    }
}

#Preview {
    SearchFilterBar()
        .previewEnvironment()
}
