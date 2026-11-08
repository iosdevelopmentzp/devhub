import SwiftUI
import DevHubDomain
import DevHubUI

struct NetworkView: View {
    @Environment(NetworkStore.self) private var network
    @Environment(MockServerStore.self) private var mockServer
    @Environment(MockSetsStore.self) private var mockSets
    @Environment(BuildStore.self) private var build
    @Environment(SimulatorsStore.self) private var simulators
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigStore.self) private var config
    @Environment(\.panelOpenCount) private var openCount

    var body: some View {
        let shown = network.shownRequests
        return VStack(spacing: 0) {
            NetworkToolbar(shownCount: shown.count)
            Divider()
            if hasBaseURLVariable {
                MockServerBar()
                Divider()
            }
            if let failure = network.sourceFailure {
                NoticeBar("Network source script: \(failure)", actionTitle: "Retry") {
                    network.restartSource()
                }
                Divider()
            }
            if mockSets.isShowingRules {
                MockRulesView()
            } else {
                content(shown: shown)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.surface)
        .task(id: openCount) {
            network.prepare(target: build.target)
            await mockSets.load()
        }
        .task(id: network.sourceKey) {
            await network.followSource()
        }
    }

    private func content(shown: [NetworkRequest]) -> some View {
        ListState(
            failure: nil,
            isLoading: false,
            loadingTitle: "",
            empty: emptyMessage(shownIsEmpty: shown.isEmpty),
            noResultsFor: shown.isEmpty && session.searchText.trimmed.isEmpty == false ? session.searchText : nil
        ) {
            NetworkRequestList(
                rows: shown.map { NetworkRequestRowMapper.model(for: $0, isSelected: $0.id == network.selectedRequestID) },
                detail: network.selectedRequest.map(NetworkRequestDetailMapper.model(for:)),
                onToggle: network.toggleSelection,
                onMockThis: mockThis
            )
        }
    }

    private func mockThis(_ id: NetworkRequest.ID) {
        guard let request = network.allRequests.first(where: { $0.id == id }) else { return }
        let udid = network.selectedUDID
        let setID = mockSets.mockThis(request, preferredSetID: udid.flatMap { mockServer.settings(for: $0).setID })
        if let udid {
            mockServer.selectSet(setID, for: udid)
        }
    }

    private var hasBaseURLVariable: Bool {
        config.config.network?.baseURLVariable?.trimmed.isEmpty == false
    }

    private func emptyMessage(shownIsEmpty: Bool) -> ListMessage? {
        let model = NetworkEmptyStateMapper.model(
            hasBaseURLVariable: hasBaseURLVariable,
            hasSourceScript: network.sourceScript != nil,
            hasBootedSimulator: simulators.all.contains { $0.state == .booted && $0.isPhysical == false },
            isIntercepting: network.isIntercepting,
            hasRequests: network.allRequests.isEmpty == false || network.pendingCount > 0,
            shownIsEmpty: shownIsEmpty,
            isSearching: session.searchText.trimmed.isEmpty == false,
            filter: network.filter
        )
        return model.map { ListMessage($0.title, systemImage: $0.systemImage, description: $0.description) }
    }
}

#Preview {
    NetworkView()
        .previewEnvironment()
}
