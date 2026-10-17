import SwiftUI

struct UsageMeterBar: View {
    let meter: UsageMeter

    private var tint: Tint {
        switch meter.clampedPercent {
        case ..<70: .blue
        case ..<90: .orange
        default: .red
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(meter.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize()
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.hover)
                    Capsule()
                        .fill(tint.color)
                        .frame(width: max(3, proxy.size.width * meter.clampedPercent / 100))
                }
            }
            .frame(minWidth: 40, maxWidth: 110)
            .frame(height: 5)
            Text("\(Int(meter.clampedPercent.rounded()))%")
                .font(.caption.monospacedDigit())
                .fixedSize()
        }
    }
}

#Preview {
    UsageMeterBar(meter: UsageMeter(id: "a", title: "Session", percent: 42, resetsAt: nil, detail: nil))
        .padding()
}
