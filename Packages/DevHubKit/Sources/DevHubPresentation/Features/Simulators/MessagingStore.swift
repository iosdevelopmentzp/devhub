import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class MessagingStore {
    var url = ""
    var payload: String
    private(set) var urlHistory: [String] {
        didSet { store.set(urlHistory, forKey: Keys.urls) }
    }
    private(set) var payloadHistory: [String] {
        didSet { store.set(payloadHistory, forKey: Keys.payloads) }
    }
    private(set) var busyIDs: Set<Simulator.ID> = []
    private(set) var schemes: [String] = []

    @ObservationIgnored private let repository: SimulatorMessagingRepository
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let identity: any IdentityLookup
    @ObservationIgnored private let runner: ActionRunner
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let store: any KeyValueStore

    init(repository: SimulatorMessagingRepository, session: ProjectSession, identity: any IdentityLookup, activity: ActivityLog, events: AppEvents, store: any KeyValueStore) {
        self.repository = repository
        self.session = session
        self.identity = identity
        runner = ActionRunner(activity: activity)
        self.events = events
        self.store = store
        urlHistory = store.strings(forKey: Keys.urls) ?? []
        payloadHistory = store.strings(forKey: Keys.payloads) ?? []
        payload = Self.alertTemplate(title: session.selectedProject.name)
    }

    var alertTemplate: String {
        Self.alertTemplate(title: session.selectedProject.name)
    }

    func bundleID(for simulator: Simulator) -> String {
        identity.bundleID(for: simulator.id)
    }

    func loadSchemes(for simulator: Simulator) async {
        let found = await repository.urlSchemes(bundleID: bundleID(for: simulator), udid: simulator.id)
        let values = found.map { $0 + "://" }
        guard values != schemes else { return }
        schemes = values
    }

    var payloadError: String? {
        PushPayloadValidator.error(in: payload)
    }

    func isBusy(_ id: Simulator.ID) -> Bool {
        busyIDs.contains(id)
    }

    func openURL(on simulator: Simulator) {
        let value = url.trimmed
        guard value.isEmpty == false else { return }
        remember(value, in: \.urlHistory, limit: 15)
        perform("Opened \(value)", on: simulator) { [repository] in
            try await repository.openURL(value, udid: simulator.id)
        }
    }

    func sendPush(to simulator: Simulator) {
        guard payloadError == nil else { return }
        let value = payload
        let bundleID = bundleID(for: simulator)
        remember(value, in: \.payloadHistory, limit: 10)
        perform("Sent push to \(bundleID)", on: simulator) { [repository] in
            try await repository.sendPush(value, bundleID: bundleID, udid: simulator.id)
        }
    }

    func forget(url value: String) {
        urlHistory.removeAll { $0 == value }
    }

    private func remember(_ value: String, in keyPath: ReferenceWritableKeyPath<MessagingStore, [String]>, limit: Int) {
        var list = self[keyPath: keyPath]
        list.removeAll { $0 == value }
        list.insert(value, at: 0)
        self[keyPath: keyPath] = Array(list.prefix(limit))
    }

    private func perform(_ title: String, on simulator: Simulator, _ work: @escaping () async throws -> Void) {
        busyIDs.insert(simulator.id)
        runner.run(
            title,
            detail: simulator.name,
            onFailure: { [events] in events.post(.commandFailed) },
            completion: { [weak self] in
                guard let self else { return }
                busyIDs.remove(simulator.id)
            },
            work: work
        )
    }

    static func alertTemplate(title: String) -> String {
        """
        {
          "aps": {
            "alert": {
              "title": "\(title.replacingOccurrences(of: "\"", with: "\\\""))",
              "body": "Test notification from DevHub"
            },
            "sound": "default",
            "badge": 1
          }
        }
        """
    }

    static let silentTemplate = """
    {
      "aps": {
        "content-available": 1
      }
    }
    """

    private enum Keys {
        static let urls = "messaging.urls"
        static let payloads = "messaging.payloads"
    }
}
