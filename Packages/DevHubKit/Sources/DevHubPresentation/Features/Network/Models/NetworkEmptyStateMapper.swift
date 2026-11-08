import Foundation
import DevHubDomain
import DevHubUI

enum NetworkEmptyStateMapper {

    static func model(
        hasBaseURLVariable: Bool,
        hasSourceScript: Bool,
        hasBootedSimulator: Bool,
        isIntercepting: Bool,
        hasRequests: Bool,
        shownIsEmpty: Bool,
        isSearching: Bool,
        filter: NetworkRequestFilter
    ) -> NetworkEmptyStateModel? {
        if hasRequests == false {
            guard hasBaseURLVariable || hasSourceScript else { return noVariable }
            guard hasBootedSimulator else { return noSimulator }
            guard isIntercepting || hasSourceScript == false else { return waitingForScript }
            guard isIntercepting else { return serverOff }
            return waiting
        }
        guard shownIsEmpty, isSearching == false, filter != .all else { return nil }
        return NetworkEmptyStateModel(
            title: "No \(NetworkToolbarMapper.title(for: filter).lowercased()) requests",
            systemImage: "line.3.horizontal.decrease.circle",
            description: "Choose All to see every request."
        )
    }

    private static let noVariable = NetworkEmptyStateModel(
        title: "Network mocks are off for this project",
        systemImage: "network.slash",
        description: "Set network.baseURLVariable in .devhub/project.json. DevHub puts the URL of its mock server into that variable when it launches the app. Or set network.sourceScript: a script that reads the requests of the app, for example from its log file."
    )

    private static let waitingForScript = NetworkEmptyStateModel(
        title: "Waiting for requests…",
        systemImage: "doc.text.magnifyingglass",
        description: "DevHub runs network.sourceScript for this simulator. Use the app; the requests the script reports show here. Start the mock server to see exact timing and to mock answers."
    )

    private static let noSimulator = NetworkEmptyStateModel(
        title: "No simulator booted",
        systemImage: "iphone.slash",
        description: "Boot a simulator and run the app from DevHub."
    )

    private static let serverOff = NetworkEmptyStateModel(
        title: "Mock server is off",
        systemImage: "network",
        description: "Start the server in Passthrough mode and relaunch the app from DevHub to see its requests. Tokens are masked. Nothing is saved to disk."
    )

    private static let waiting = NetworkEmptyStateModel(
        title: "Waiting for requests…",
        systemImage: "arrow.left.arrow.right",
        description: "The mock server is on for this simulator. Use the app; every REST call shows here with exact timing."
    )
}
