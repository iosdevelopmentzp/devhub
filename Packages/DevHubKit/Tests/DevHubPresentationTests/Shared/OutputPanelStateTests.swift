import DevHubMocks
import Testing
@testable import DevHubPresentation

@Suite struct OutputPanelStateTests {
    let store = InMemoryKeyValueStore()
    let events = AppEvents()

    @Test func startsHiddenWithoutReads() {
        let state = OutputPanelState(store: store, events: events)

        #expect(state.isVisible == false)
        #expect(state.showsReads == false)
    }

    @Test func readsSavedValues() {
        store.set(true, forKey: "output.visible")
        store.set(true, forKey: "output.showsReads")

        let state = OutputPanelState(store: store, events: events)

        #expect(state.isVisible)
        #expect(state.showsReads)
    }

    @Test func changesAreSaved() {
        let state = OutputPanelState(store: store, events: events)

        state.isVisible = true
        state.showsReads = true

        #expect(store.bool(forKey: "output.visible"))
        #expect(store.bool(forKey: "output.showsReads"))
    }

    @Test func commandFailedShowsThePanel() {
        let state = OutputPanelState(store: store, events: events)

        events.post(.commandFailed)

        #expect(state.isVisible)
        #expect(store.bool(forKey: "output.visible"))
    }

    @Test func otherEventsKeepThePanelHidden() {
        let state = OutputPanelState(store: store, events: events)

        events.post(.branchesChanged)
        events.post(.projectChanged)

        #expect(state.isVisible == false)
    }
}
