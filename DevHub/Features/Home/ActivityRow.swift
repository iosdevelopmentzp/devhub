import SwiftUI

struct ActivityRow: View {
    let event: ActivityEvent

    private var tint: Tint {
        switch event.outcome {
        case .success: .green
        case .failure: .red
        case .info: .gray
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            StatusDot(color: tint)
            Text(event.title)
                .font(.callout.weight(.medium))
                .lineLimit(1)
            Text(event.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .hintWhenTruncated(event.detail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(event.date, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 7)
    }
}

#Preview {
    ActivityRow(event: ActivityEvent(id: UUID(), date: Date(), title: "Open in Finder", detail: "/tmp", outcome: .success))
        .padding()
        .previewEnvironment()
}
