import SwiftUI
import DevHubDomain
import DevHubUI

struct UsageBar: View {
    let model: UsageMeterModel

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.1))
                Capsule()
                    .fill(model.levelTint?.color ?? .accentColor)
                    .frame(width: max(5, proxy.size.width * min(max(model.fraction, 0), 1)))
            }
        }
        .frame(height: 5)
    }
}

#Preview {
    UsageBar(model: .preview)
        .frame(width: 160)
        .padding()
}
