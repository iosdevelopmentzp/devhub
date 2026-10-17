import SwiftUI

struct SimulatorSectionView: View {
    let section: SimulatorSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                if section.isFavorites {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Tint.yellow.color)
                }
                Text(section.title.uppercased())
                    .font(.caption.weight(.semibold))
                    .kerning(0.6)
                    .foregroundStyle(.secondary)
                Text("· \(section.countText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)
            VStack(spacing: 0) {
                ForEach(section.simulators) { simulator in
                    SimulatorRow(simulator: simulator)
                    if simulator.id != section.simulators.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Theme.surface)
            .overlay(alignment: .top) { Divider() }
            .overlay(alignment: .bottom) { Divider() }
        }
    }
}

#Preview {
    SimulatorSectionView(section: SimulatorSection(
        id: "iOS 26.0",
        title: "iOS 26.0",
        isFavorites: false,
        simulators: [SimulatorInfo(id: "A", name: "iPhone 17", runtime: "iOS 26.0", state: .booted, appCount: 1, isFavorite: false)]
    ))
    .previewEnvironment()
}
