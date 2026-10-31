import SwiftUI
import DevHubDomain
import DevHubUI

struct BuildStatusLabel: View {
    let phase: BuildState.Phase

    var body: some View {
        HStack(spacing: 6) {
            switch phase {
            case .idle:
                StatusDot(color: Color.secondary.opacity(0.5))
                Text("Ready")
            case .running(let step, _):
                ProgressView()
                    .controlSize(.mini)
                Text(step)
            case .succeeded(let date, _):
                StatusDot(color: .green)
                Text("Build succeeded · \(date.relativeDescription)")
            case .failed(let message):
                StatusDot(color: .red)
                Text(message)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}
