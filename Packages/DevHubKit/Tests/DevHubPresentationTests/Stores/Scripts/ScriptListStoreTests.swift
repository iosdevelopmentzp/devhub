import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct ScriptListStoreTests {
    private let harness = StoreHarness()
    private let ids = ["script:a", "script:b", "script:c"]

    private var store: ScriptListStore {
        harness.scriptList
    }

    private var orderKey: String {
        "scripts.order.\(ProjectSample.app.id)"
    }

    private var favoritesKey: String {
        "scripts.favorites.\(ProjectSample.app.id)"
    }

    @Test func withoutSavedStateTheConfigOrderStays() {
        #expect(store.arranged(ids) == ids)
    }

    @Test func toggleFavoriteMovesTheScriptToTheTopAndSaves() {
        store.toggleFavorite("script:c", among: ids)

        #expect(store.isFavorite("script:c"))
        #expect(store.arranged(ids) == ["script:c", "script:a", "script:b"])
        #expect(harness.store.strings(forKey: favoritesKey) == ["script:c"])
        #expect(harness.store.strings(forKey: orderKey) == ["script:c", "script:a", "script:b"])
    }

    @Test func moveAndShiftChangeTheSavedOrder() {
        store.move("script:c", onto: "script:a", among: ids)

        #expect(store.arranged(ids) == ["script:c", "script:a", "script:b"])

        store.shift("script:c", by: 1, among: ids)

        #expect(store.arranged(ids) == ["script:a", "script:c", "script:b"])
    }

    @Test func savedOrderKeepsScriptsThatAreMissingNow() {
        store.move("script:c", onto: "script:a", among: ids)

        store.shift("script:a", by: 1, among: ["script:a", "script:b"])

        #expect(store.order == ["script:b", "script:a", "script:c"])
    }

    @Test func stateIsRestored() {
        store.toggleFavorite("script:b", among: ids)

        let reloaded = ScriptListStore(session: harness.session, events: harness.events, store: harness.store)

        #expect(reloaded.favorites == ["script:b"])
        #expect(reloaded.arranged(ids) == ["script:b", "script:a", "script:c"])
    }

    @Test func eachProjectHasItsOwnOrder() {
        store.toggleFavorite("script:b", among: ids)

        harness.session.selectedProjectID = ProjectSample.other.id

        #expect(store.favorites.isEmpty)
        #expect(store.arranged(ids) == ids)

        harness.session.selectedProjectID = ProjectSample.app.id

        #expect(store.favorites == ["script:b"])
    }
}
