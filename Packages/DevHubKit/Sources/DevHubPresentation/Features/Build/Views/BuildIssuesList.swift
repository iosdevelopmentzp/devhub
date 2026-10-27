import SwiftUI
import DevHubUI

struct BuildIssuesList: View {
    let title: String
    let rows: [BuildIssueRowModel]
    let onOpen: (BuildIssueRowModel) -> Void

    @State private var showsAll = false

    private static let collapsedCount = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if rows.count > Self.collapsedCount {
                    Button(showsAll ? "Show fewer" : "Show all \(rows.count)") {
                        showsAll.toggle()
                    }
                    .buttonStyle(LinkButtonStyle(.accent))
                    .font(.caption)
                }
            }
            ForEach(showsAll ? rows : Array(rows.prefix(Self.collapsedCount))) { row in
                Button {
                    onOpen(row)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: row.icon)
                            .font(.caption)
                            .foregroundStyle(row.tint.color)
                        if let location = row.location {
                            Text(location)
                                .font(.caption.monospaced())
                                .lineLimit(1)
                        }
                        Text(row.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(row.path == nil)
                .hint(row.hint)
            }
        }
    }
}

#Preview {
    BuildIssuesList(title: "1 error", rows: [.preview], onOpen: { _ in })
        .padding()
        .frame(width: 560)
}
