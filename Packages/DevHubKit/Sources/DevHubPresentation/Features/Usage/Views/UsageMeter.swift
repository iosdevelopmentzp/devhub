import SwiftUI
import DevHubDomain
import DevHubUI

struct UsageMeter: View {
    let model: UsageMeterModel

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(model.title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(model.percentText)
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(model.levelTint?.color ?? .accentColor)
            }
            UsageBar(model: model)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    UsageMeter(model: .preview)
        .frame(width: 180)
        .padding()
}
