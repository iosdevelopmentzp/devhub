import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class MockSetsStore: MockSetLookup {
    private(set) var sets: [MockSet] = []
    private(set) var isLoading = false
    private(set) var error: String?
    var editingRuleID: MockRule.ID?
    var isShowingRules = false

    @ObservationIgnored private let repository: any MockSetRepository
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?
    @ObservationIgnored private var loadedLocation: MockSetLocation?

    init(repository: any MockSetRepository, session: ProjectSession, config: ConfigStore, activity: ActivityLog, events: AppEvents) {
        self.repository = repository
        self.session = session
        self.config = config
        self.activity = activity
        self.events = events
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                sets = []
                editingRuleID = nil
                loadedLocation = nil
                Task { await self.load() }
            case .configChanged:
                guard location != loadedLocation else { return }
                Task { await self.load() }
            case .refreshRequested(.network):
                Task { await self.load() }
            default:
                break
            }
        }
    }

    var location: MockSetLocation {
        MockSetLocationPolicy.location(network: config.config.network, projectPath: session.selectedProject.path)
    }

    func set(id: MockSet.ID) -> MockSet? {
        sets.first { $0.id == id }
    }

    func load() async {
        isLoading = true
        await refreshTask.run { [weak self] in
            guard let self else { return }
            do {
                let location = location
                let loaded = try await repository.list(in: location)
                try Task.checkCancellation()
                sets = loaded
                loadedLocation = location
                error = nil
            } catch is CancellationError {
            } catch {
                self.error = error.localizedDescription
            }
        }
        isLoading = false
    }

    // MARK: Sets

    @discardableResult
    func createSet(name: String) -> MockSet.ID {
        let set = MockSet(id: UUID(), name: uniqueName(name), rules: [])
        sets.append(set)
        persist(set, title: "Created mock set")
        return set.id
    }

    func renameSet(id: MockSet.ID, to name: String) {
        let trimmed = name.trimmed
        guard trimmed.isEmpty == false, var set = set(id: id), set.name != trimmed else { return }
        set.name = uniqueName(trimmed)
        replace(set)
        persist(set, title: "Renamed mock set")
    }

    @discardableResult
    func duplicateSet(id: MockSet.ID) -> MockSet.ID? {
        guard let original = set(id: id) else { return nil }
        let copy = MockSet(
            id: UUID(),
            name: uniqueName("\(original.name) copy"),
            rules: original.rules.map { MockRule(id: UUID(), isEnabled: $0.isEnabled, method: $0.method, pathPattern: $0.pathPattern, query: $0.query, action: $0.action, operationName: $0.operationName) }
        )
        sets.append(copy)
        persist(copy, title: "Duplicated mock set")
        return copy.id
    }

    func deleteSet(id: MockSet.ID) {
        guard let set = set(id: id) else { return }
        sets.removeAll { $0.id == id }
        let location = location
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.delete(id: id, in: location)
                activity.log("Deleted mock set", detail: set.name, outcome: .success)
            } catch {
                fail("Could not delete mock set \(set.name)", error)
            }
        }
        events.post(.mockSetChanged(id: id))
    }

    // MARK: Rules

    @discardableResult
    func addRule(to setID: MockSet.ID) -> MockRule.ID? {
        guard var set = set(id: setID) else { return nil }
        let rule = MockRuleFactory.newRule(id: UUID())
        set.rules.append(rule)
        replace(set)
        persist(set, title: nil)
        editingRuleID = rule.id
        return rule.id
    }

    func saveRule(_ rule: MockRule, in setID: MockSet.ID) {
        guard var set = set(id: setID), let index = set.rules.firstIndex(where: { $0.id == rule.id }) else { return }
        set.rules[index] = rule
        replace(set)
        persist(set, title: nil)
        editingRuleID = nil
    }

    func toggleRule(id: MockRule.ID, in setID: MockSet.ID) {
        guard var set = set(id: setID), let index = set.rules.firstIndex(where: { $0.id == id }) else { return }
        set.rules[index].isEnabled.toggle()
        replace(set)
        persist(set, title: nil)
    }

    func deleteRule(id: MockRule.ID, in setID: MockSet.ID) {
        guard var set = set(id: setID) else { return }
        set.rules.removeAll { $0.id == id }
        if editingRuleID == id {
            editingRuleID = nil
        }
        replace(set)
        persist(set, title: nil)
    }

    func toggleEditing(_ id: MockRule.ID) {
        editingRuleID = editingRuleID == id ? nil : id
    }

    @discardableResult
    func mockThis(_ request: NetworkRequest, preferredSetID: MockSet.ID?) -> MockSet.ID {
        let setID = preferredSetID.flatMap { set(id: $0)?.id } ?? sets.first?.id ?? createSet(name: "Mocks")
        guard var set = set(id: setID) else { return setID }
        let rule = MockRuleFactory.respondRule(from: request, id: UUID())
        set.rules.insert(rule, at: 0)
        replace(set)
        persist(set, title: "Added mock rule")
        editingRuleID = rule.id
        isShowingRules = true
        return setID
    }

    // MARK: Helpers

    private func replace(_ set: MockSet) {
        guard let index = sets.firstIndex(where: { $0.id == set.id }) else { return }
        sets[index] = set
    }

    private func persist(_ set: MockSet, title: String?) {
        events.post(.mockSetChanged(id: set.id))
        let location = location
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.save(set, in: location)
                if let title {
                    activity.log(title, detail: set.name, outcome: .success)
                }
            } catch {
                fail("Could not save mock set \(set.name)", error)
            }
        }
    }

    private func fail(_ title: String, _ error: Error) {
        self.error = error.localizedDescription
        activity.log(title, detail: error.localizedDescription, outcome: .failure)
    }

    private func uniqueName(_ name: String) -> String {
        let base = name.trimmed.isEmpty ? "Mocks" : name.trimmed
        let taken = Set(sets.map(\.name))
        guard taken.contains(base) else { return base }
        var counter = 2
        while taken.contains("\(base) \(counter)") {
            counter += 1
        }
        return "\(base) \(counter)"
    }
}
