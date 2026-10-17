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
    @Environment(\.panelOpenCount) private var openCount

    var body: some View {
        let shown = network.shownRequests
        return VStack(spacing: 0) {
            NetworkToolbar(shownCount: shown.count)
            Divider()
            MockServerBar()
            Divider()
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

    private func emptyMessage(shownIsEmpty: Bool) -> ListMessage? {
        if network.allRequests.isEmpty, network.pendingCount == 0 {
            guard simulators.all.contains(where: { $0.state == .booted }) else {
                return ListMessage("No simulator booted", systemImage: "iphone.slash", description: "Boot a simulator and run the app from DevHub.")
            }
            guard network.isIntercepting else {
                return ListMessage("Mock server is off", systemImage: "network", description: "Start the server in Passthrough mode and relaunch the app from DevHub to see its requests. Tokens are masked. Nothing is saved to disk.")
            }
            return ListMessage("Waiting for requests…", systemImage: "arrow.left.arrow.right", description: "The mock server is on for this simulator. Use the app; every REST call shows here with exact timing.")
        }
        guard shownIsEmpty, session.searchText.trimmed.isEmpty, network.filter != .all else { return nil }
        return ListMessage(
            "No \(NetworkToolbarMapper.title(for: network.filter).lowercased()) requests",
            systemImage: "line.3.horizontal.decrease.circle",
            description: "Choose All to see every request."
        )
    }
}

#Preview {
    NetworkView()
        .previewEnvironment()
}
