import SwiftUI

struct SimulatorSendPopover: View {
    enum Mode: String, CaseIterable {
        case link = "Deep link"
        case push = "Push"
    }

    let simulator: SimulatorInfo

    @State private var mode = Mode.link

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Send", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            Text(simulator.longTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            switch mode {
            case .link: DeepLinkForm(simulator: simulator)
            case .push: PushForm(simulator: simulator)
            }
        }
        .padding(12)
        .frame(width: 360)
    }
}

#Preview {
    SimulatorSendPopover(simulator: SimulatorInfo(id: "A", name: "iPhone 17", runtime: "iOS 26.0", state: .booted, appCount: 1, isFavorite: false))
        .previewEnvironment()
}
