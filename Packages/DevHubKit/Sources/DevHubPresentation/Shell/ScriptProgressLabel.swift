import SwiftUI
import DevHubDomain
import DevHubUI

struct ScriptProgressLabel: View {
    let progress: ConfigActionProgress

    var body: some View {
        HStack(spacing: 6) {
            if let fraction = progress.fraction {
                ProgressView(value: min(max(fraction, 0), 1))
                    .frame(width: 60)
                    .controlSize(.mini)
            } else {
                ProgressView()
                    .controlSize(.mini)
            }
            Text("\(progress.actionTitle): \(progress.text)")
                .hintWhenTruncated("\(progress.actionTitle): \(progress.text)")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}

#Preview {
    ScriptProgressLabel(progress: ConfigActionProgress(actionID: "x", actionTitle: "Regenerate", text: "Step 2 of 3", fraction: 0.6))
        .padding()
}
