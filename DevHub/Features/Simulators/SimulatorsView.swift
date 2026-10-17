import SwiftUI

struct SimulatorsView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(SimulatorsStore.self) private var store
    @Environment(BuildStore.self) private var build

    private var sections: [SimulatorSection] {
        SimulatorSection.build(from: store.simulators.filter { session.matchesSearch($0.name, $0.runtime) })
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    RunBarCard()
                        .padding(14)
                    SimulatorsSummaryBar()
                    list
                }
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.base)
        .task {
            await store.refresh()
            await build.loadConfigurations()
        }
    }

    @ViewBuilder
    private var list: some View {
        let current = sections
        if let error = store.error {
            InlineError(text: error) { Task { await store.refresh() } }
        } else if store.simulators.isEmpty {
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(24)
            } else {
                EmptyState(systemImage: "iphone", title: "No simulators", text: "No iOS simulator is installed. Add one in Xcode.")
            }
        } else if current.isEmpty {
            ContentUnavailableView.search(text: session.searchText)
        } else {
            ForEach(current) { section in
                SimulatorSectionView(section: section)
            }
        }
    }
}

#Preview {
    SimulatorsView()
        .previewEnvironment()
}
