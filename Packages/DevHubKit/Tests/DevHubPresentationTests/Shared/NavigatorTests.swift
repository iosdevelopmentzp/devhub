import DevHubDomain
import DevHubMocks
import Testing
@testable import DevHubPresentation

@Suite struct NavigatorTests {
    let store = InMemoryKeyValueStore()
    private let tabs = CustomTabs()

    private func navigator() -> Navigator {
        Navigator(store: store, customTabs: tabs)
    }

    // MARK: Selection

    @Test func defaultsToHome() {
        #expect(navigator().selection == .feature(.home))
    }

    @Test func readsTheSavedSelection() {
        store.set("git", forKey: "navigator.selection")

        #expect(navigator().selection == .feature(.git))
    }

    @Test func unknownSavedValueFallsBackToHome() {
        store.set("scripts", forKey: "navigator.selection")

        #expect(navigator().selection == .feature(.home))
    }

    @Test func changingSelectionSavesIt() {
        let navigator = navigator()

        navigator.selection = .feature(.logs)

        #expect(store.string(forKey: "navigator.selection") == "logs")
    }

    @Test func showSelectsTheFeature() {
        let navigator = navigator()

        navigator.show(.ai)

        #expect(navigator.selection == .feature(.ai))
        #expect(navigator.currentTab == .feature(.ai))
        #expect(store.string(forKey: "navigator.selection") == "ai")
    }

    @Test func settingTheSameValueDoesNotWrite() {
        let navigator = navigator()

        navigator.selection = .feature(.home)

        #expect(store.string(forKey: "navigator.selection") == nil)
    }

    @Test func aCustomTabPlacedInTheBarIsSavedWithItsPrefix() {
        tabs.customTabs = [TabConfig(id: "qa", title: "QA", placement: .bar)]
        let navigator = navigator()

        navigator.show(tab: "qa")

        #expect(navigator.selection == .custom("qa"))
        #expect(store.string(forKey: "navigator.selection") == "tab.qa")
        #expect(self.navigator().selection == .custom("qa"))
    }

    @Test func togglingThePaletteClearsTheQuery() {
        let navigator = navigator()
        navigator.paletteQuery = "old"

        navigator.togglePalette()

        #expect(navigator.isPaletteOpen)
        #expect(navigator.paletteQuery == "")
        navigator.togglePalette()
        #expect(navigator.isPaletteOpen == false)
    }

    // MARK: Utils

    @Test func utilsStartsOnCompressVideo() {
        let navigator = navigator()

        #expect(navigator.utilsSelection == .utility(.compressVideo))
        #expect(navigator.utilsTab == .utility(.compressVideo))
        #expect(navigator.tabs(in: .utils) == [.utility(.compressVideo)])
    }

    @Test func aSavedUtilitySelectionIsReadInBothForms() {
        store.set("compressVideo", forKey: "utils.selection")
        #expect(navigator().utilsSelection == .utility(.compressVideo))

        store.set("utility.compressVideo", forKey: "utils.selection")
        #expect(navigator().utilsSelection == .utility(.compressVideo))

        store.set("removedTool", forKey: "utils.selection")
        #expect(navigator().utilsSelection == .utility(.compressVideo))
    }

    @Test func aCustomTabOpensInsideUtilsByDefault() {
        tabs.customTabs = [TabConfig(id: "qa", title: "QA")]
        let navigator = navigator()

        navigator.show(tab: "qa")

        #expect(navigator.selection == .feature(.utils))
        #expect(navigator.utilsSelection == .custom("qa"))
        #expect(navigator.currentTab == .custom("qa"))
        #expect(store.string(forKey: "navigator.selection") == "utils")
        #expect(store.string(forKey: "utils.selection") == "tab.qa")
    }

    @Test func aStaleUtilsSelectionFallsBackToTheFirstUtilsTab() {
        store.set("tab.gone", forKey: "utils.selection")
        let navigator = navigator()

        navigator.show(.utils)

        #expect(navigator.utilsSelection == .custom("gone"))
        #expect(navigator.utilsTab == .utility(.compressVideo))
        #expect(navigator.currentTab == .utility(.compressVideo))
    }

    // MARK: Layout

    @Test func movingTheShownTabToUtilsKeepsItOnScreenAndSavesTheLayout() {
        let navigator = navigator()
        navigator.show(.logs)

        navigator.move(.feature(.logs), to: .utils)

        #expect(navigator.selection == .feature(.utils))
        #expect(navigator.utilsSelection == .feature(.logs))
        #expect(navigator.placement(of: .feature(.logs)) == .utils)
        #expect(navigator.tabs(in: .utils) == [.feature(.logs), .utility(.compressVideo)])
        #expect(store.stringMap(forKey: "tabs.layout") == ["logs": "utils"])
        #expect(self.navigator().placement(of: .feature(.logs)) == .utils)
    }

    @Test func movingAnotherTabLeavesTheSelectionAlone() {
        let navigator = navigator()
        navigator.show(.git)

        navigator.move(.feature(.network), to: .utils)

        #expect(navigator.selection == .feature(.git))
        #expect(navigator.utilsSelection == .utility(.compressVideo))
    }

    @Test func showingAUtilityInTheBarSelectsItThere() {
        let navigator = navigator()
        navigator.show(.utils)

        navigator.move(.utility(.compressVideo), to: .bar)

        #expect(navigator.selection == .utility(.compressVideo))
        #expect(navigator.tabs(in: .bar).last == .utility(.compressVideo))
        #expect(navigator.utilsTab == nil)
        #expect(store.string(forKey: "navigator.selection") == "utility.compressVideo")
    }

    @Test func theUserLayoutWinsOverTheConfigPlacement() {
        tabs.customTabs = [TabConfig(id: "qa", title: "QA", placement: .bar)]
        let navigator = navigator()

        navigator.move(.custom("qa"), to: .utils)
        navigator.show(tab: "qa")

        #expect(navigator.selection == .feature(.utils))
        #expect(navigator.utilsTab == .custom("qa"))
    }

    @Test func homeAndUtilsDoNotMove() {
        let navigator = navigator()

        navigator.move(.feature(.home), to: .utils)
        navigator.move(.feature(.utils), to: .utils)

        #expect(navigator.canMove(.feature(.home)) == false)
        #expect(navigator.tabs(in: .bar).prefix(1) == [.feature(.home)])
        #expect(store.stringMap(forKey: "tabs.layout") == nil)
    }
}

private final class CustomTabs: CustomTabLookup {
    var customTabs: [TabConfig] = []
}
