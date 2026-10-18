import DevHubMocks
import Testing
@testable import DevHubPresentation

@Suite struct NavigatorTests {
    let store = InMemoryKeyValueStore()

    @Test func defaultsToHome() {
        #expect(Navigator(store: store).selection == .feature(.home))
    }

    @Test func readsTheSavedSelection() {
        store.set("git", forKey: "navigator.selection")

        #expect(Navigator(store: store).selection == .feature(.git))
    }

    @Test func unknownSavedValueFallsBackToHome() {
        store.set("scripts", forKey: "navigator.selection")

        #expect(Navigator(store: store).selection == .feature(.home))
    }

    @Test func changingSelectionSavesIt() {
        let navigator = Navigator(store: store)

        navigator.selection = .feature(.logs)

        #expect(store.string(forKey: "navigator.selection") == "logs")
    }

    @Test func showSelectsTheFeature() {
        let navigator = Navigator(store: store)

        navigator.show(.ai)

        #expect(navigator.selection == .feature(.ai))
        #expect(store.string(forKey: "navigator.selection") == "ai")
    }

    @Test func settingTheSameValueDoesNotWrite() {
        let navigator = Navigator(store: store)

        navigator.selection = .feature(.home)

        #expect(store.string(forKey: "navigator.selection") == nil)
    }

    @Test func aCustomTabIsSavedWithItsPrefix() {
        let navigator = Navigator(store: store)

        navigator.show(tab: "qa")

        #expect(navigator.selection == .custom("qa"))
        #expect(store.string(forKey: "navigator.selection") == "tab.qa")
        #expect(Navigator(store: store).selection == .custom("qa"))
    }
}
