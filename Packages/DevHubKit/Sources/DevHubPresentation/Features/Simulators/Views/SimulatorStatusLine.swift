import SwiftUI
import DevHubDomain
import DevHubUI

struct SimulatorStatusLine: View {
    let model: SimulatorStatusLineModel

    var body: some View {
        Text(model.text)
            .font(.caption)
            .foregroundStyle(model.tint.color)
            .lineLimit(1)
            .hintWhenTruncated(model.text)
    }
}

#Preview {
    SimulatorStatusLine(model: .preview)
        .padding()
}
