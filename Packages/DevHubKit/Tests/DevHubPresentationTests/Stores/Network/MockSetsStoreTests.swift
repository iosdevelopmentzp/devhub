import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct MockSetsStoreTests {
    private let harness = StoreHarness()
    private let location = MockSetLocation.defaultFolder(project: "App")

    private var store: MockSetsStore {
        harness.mockSets
    }

    private func load() async {
        harness.spies.mockSets.listResult = .success([MockSetSample.vip, MockSetSample.empty])
        await store.load()
    }

    @Test func loadListsTheSetsOfTheProjectFolder() async {
        await load()

        #expect(store.sets == [MockSetSample.vip, MockSetSample.empty])
        #expect(harness.spies.mockSets.calls == [.list(in: location)])
        #expect(store.error == nil)
    }

    @Test func loadFailureIsShown() async {
        harness.spies.mockSets.listResult = .failure(MockSetError.unreadable(file: "a.json", reason: "bad"))

        await store.load()

        #expect(store.error == MockSetError.unreadable(file: "a.json", reason: "bad").localizedDescription)
    }

    @Test func createSetSavesPostsAndKeepsNamesUnique() async throws {
        await load()

        let id = store.createSet(name: "VIP")

        #expect(store.set(id: id)?.name == "VIP 2")
        #expect(harness.postedLabels.contains("mockSetChanged(\(id))"))
        try await waitUntil { harness.spies.mockSets.savedSets.map(\.id) == [id] }
        try await waitUntil { harness.lastActivity?.title == "Created mock set" }
    }

    @Test func renameDuplicateAndDelete() async throws {
        await load()

        store.renameSet(id: MockSetSample.vip.id, to: "  Premium ")
        let copy = try #require(store.duplicateSet(id: MockSetSample.vip.id))
        store.deleteSet(id: MockSetSample.empty.id)

        #expect(store.sets.map(\.name) == ["Premium", "Premium copy"])
        #expect(store.set(id: copy)?.rules.map(\.pathPattern) == ["/v1/settings/list"])
        #expect(store.set(id: copy)?.rules.first?.id != MockSetSample.ruleID)
        try await waitUntil { harness.spies.mockSets.calls.contains(.delete(id: MockSetSample.empty.id, in: location)) }
    }

    @Test func addRuleOpensItAndSaveRuleClosesTheEditor() async throws {
        await load()

        let id = try #require(store.addRule(to: MockSetSample.empty.id))
        #expect(store.editingRuleID == id)

        var rule = try #require(store.set(id: MockSetSample.empty.id)?.rules.first)
        rule.pathPattern = "/v1/wallet"
        store.saveRule(rule, in: MockSetSample.empty.id)

        #expect(store.editingRuleID == nil)
        #expect(store.set(id: MockSetSample.empty.id)?.rules.map(\.pathPattern) == ["/v1/wallet"])
        try await waitUntil { harness.spies.mockSets.savedSets.last?.rules.first?.pathPattern == "/v1/wallet" }
    }

    @Test func toggleAndDeleteRule() async {
        await load()

        store.toggleRule(id: MockSetSample.ruleID, in: MockSetSample.vip.id)
        #expect(store.set(id: MockSetSample.vip.id)?.rules.first?.isEnabled == false)

        store.deleteRule(id: MockSetSample.ruleID, in: MockSetSample.vip.id)
        #expect(store.set(id: MockSetSample.vip.id)?.rules.isEmpty == true)
    }

    @Test func mockThisAddsARespondRuleToThePreferredSetAndOpensIt() async throws {
        await load()
        var request = NetworkRequestSample.failed
        request.responseBody = #"{"error":"x"}"#

        let setID = store.mockThis(request, preferredSetID: MockSetSample.empty.id)

        let rule = try #require(store.set(id: setID)?.rules.first)
        #expect(setID == MockSetSample.empty.id)
        #expect(rule.method == "POST")
        #expect(rule.pathPattern == "/v1/chat/messages")
        #expect(rule.action == .respond(MockResponse(status: 422, headers: [], body: #"{"error":"x"}"#, delay: 0)))
        #expect(store.editingRuleID == rule.id)
        #expect(store.isShowingRules)
    }

    @Test func mockThisWithoutSetsCreatesOne() async throws {
        let setID = store.mockThis(NetworkRequestSample.ok, preferredSetID: nil)

        #expect(store.sets.map(\.name) == ["Mocks"])
        #expect(store.set(id: setID)?.rules.count == 1)
    }

    @Test func saveFailureIsLogged() async throws {
        await load()
        harness.spies.mockSets.saveError = MockSetError.writeFailed("disk full")

        store.toggleRule(id: MockSetSample.ruleID, in: MockSetSample.vip.id)

        try await waitUntil { store.error == MockSetError.writeFailed("disk full").localizedDescription }
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func projectChangeReloads() async throws {
        await load()

        harness.events.post(.projectChanged)

        try await waitUntil { harness.spies.mockSets.calls.filter { $0 == .list(in: location) }.count == 2 }
    }

    @Test func aConfiguredMocksFolderIsReadAndAChangeReloads() async throws {
        await load()
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(network: NetworkConfig(mocksFolder: "Mocks")), actions: [], tabs: [], issues: [], layers: [])

        await harness.config.reload()

        let folder = MockSetLocation.folder(ProjectSample.path + "/Mocks")
        try await waitUntil { harness.spies.mockSets.calls.contains(.list(in: folder)) }
        #expect(store.location == folder)
    }

    @Test func aConfigChangeWithTheSameFolderDoesNotReload() async {
        await load()
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(name: "Renamed"), actions: [], tabs: [], issues: [], layers: [])

        await harness.config.reload()
        await harness.settle()

        #expect(harness.spies.mockSets.calls == [.list(in: location)])
    }
}
