import SwiftUI
import DevHubUI

struct TodayCard: View {
    let items: [TodayItemModel]
    let onOpen: (TodayTarget) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Today")
            PanelCard {
                if items.isEmpty {
                    Label(TodayCardMapper.emptyTitle, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(items) { item in
                            row(item)
                            if item.id != items.last?.id {
                                Divider()
                                    .padding(.vertical, 6)
                            }
                        }
                    }
                }
            }
        }
    }

    private func row(_ item: TodayItemModel) -> some View {
        Button {
            onOpen(item.target)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .foregroundStyle(item.tint.color)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(.callout)
                        .lineLimit(1)
                        .hintWhenTruncated(item.title)
                    if let detail = item.detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TodayCard(items: [.preview], onOpen: { _ in })
        .padding()
        .frame(width: 520)
}
