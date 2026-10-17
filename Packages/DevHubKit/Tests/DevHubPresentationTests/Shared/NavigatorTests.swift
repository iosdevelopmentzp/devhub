import DevHubMocks
import Testing
@testable import DevHubPresentation

@Suite struct NavigatorTests {
    let store = InMemoryKeyValueStore()

    @Test func defaultsToHome() {
        #expect(Navigator(store: store).selection == .home)
    }

    @Test func readsTheSavedSelection() {
        store.set("git", forKey: "navigator.selection")

        #expect(Navigator(store: store).selection == .git)
    }

    @Test func unknownSavedValueFallsBackToHome() {
        store.set("scripts", forKey: "navigator.selection")

        #expect(Navigator(store: store).selection == .home)
    }

    @Test func changingSelectionSavesIt() {
        let navigator = Navigator(store: store)

        navigator.selection = .logs

        #expect(store.string(forKey: "navigator.selection") == "logs")
    }

    @Test func showSelectsTheFeature() {
        let navigator = Navigator(store: store)

        navigator.show(.claude)

        #expect(navigator.selection == .claude)
        #expect(store.string(forKey: "navigator.selection") == "claude")
    }

    @Test func settingTheSameValueDoesNotWrite() {
        let navigator = Navigator(store: store)

        navigator.selection = .home

        #expect(store.string(forKey: "navigator.selection") == nil)
    }
}
