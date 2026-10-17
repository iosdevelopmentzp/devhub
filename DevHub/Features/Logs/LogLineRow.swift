import SwiftUI

struct LogLineRow: View {
    @Environment(Toaster.self) private var toaster

    let line: LogLine

    private var tint: Tint {
        switch line.level {
        case .debug, .info: .gray
        case .notice: .blue
        case .error: .red
        case .fault: .purple
        }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(line.date, format: Date.FormatStyle().hour(.twoDigits(amPM: .omitted)).minute().second())
                .foregroundStyle(.secondary)
            Circle()
                .fill(tint.color)
                .frame(width: 6, height: 6)
            if line.source.isEmpty == false {
                Text(line.source)
                    .foregroundStyle(tint.color)
                    .lineLimit(1)
                    .frame(width: 170, alignment: .leading)
                    .hintWhenTruncated(line.source)
            }
            Text(line.message)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption.monospaced())
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { toaster.copy(line.message, label: "line") }
        .contextMenu {
            Button("Copy message", systemImage: "doc.on.doc") { toaster.copy(line.message, label: "message") }
            Button("Copy whole line", systemImage: "doc.on.doc") { toaster.copy(line.plainText, label: "line") }
        }
    }
}

#Preview {
    LogLineRow(line: LogLine(id: UUID(), date: Date(), level: .error, subsystem: "app", category: "network", message: "Request failed"))
        .previewEnvironment()
}
