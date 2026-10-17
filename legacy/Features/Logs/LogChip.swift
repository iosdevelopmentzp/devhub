import SwiftUI

struct LogChip: View {
    let stream: LogStream
    let isSelected: Bool
    let isBooted: Bool
    let select: () -> Void
    let close: () -> Void

    private var dot: Tint {
        if stream.error != nil { return .red }
        return stream.isRunning ? .green : .gray
    }

    var body: some View {
        HStack(spacing: 6) {
            StatusDot(color: dot)
            Text("\(stream.name) · \(isBooted ? "booted" : "off")")
                .font(.caption.weight(.medium))
                .lineLimit(1)
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hint("Close the stream")
        }
        .padding(.leading, 10)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Theme.hover, in: Capsule())
        .overlay(Capsule().stroke(isSelected ? Color.accentColor.opacity(0.5) : .clear, lineWidth: 1))
        .contentShape(Capsule())
        .onTapGesture(perform: select)
        .fixedSize()
    }
}

#Preview {
    LogChip(
        stream: LogStream(simulatorID: "A", name: "iPhone 17", process: "App", subsystem: "", level: .all),
        isSelected: true,
        isBooted: true,
        select: {},
        close: {}
    )
    .padding()
}
