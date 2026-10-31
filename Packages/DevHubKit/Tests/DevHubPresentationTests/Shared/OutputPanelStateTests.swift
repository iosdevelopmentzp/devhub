import DevHubMocks
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct OutputPanelStateTests {
    let store = InMemoryKeyValueStore()
    let events = AppEvents()

    @Test func startsHiddenWithoutReadsAtTheDefaultHeightAndFollowing() {
        let state = OutputPanelState(store: store, events: events)

        #expect(state.isVisible == false)
        #expect(state.showsReads == false)
        #expect(state.followsOutput)
        #expect(state.height == 260)
    }

    @Test func readsSavedValues() {
        store.set(true, forKey: "output.visible")
        store.set(true, forKey: "output.showsReads")
        store.set("off", forKey: "output.follows")
        store.set([180.0], forKey: "output.height")

        let state = OutputPanelState(store: store, events: events)

        #expect(state.isVisible)
        #expect(state.showsReads)
        #expect(state.followsOutput == false)
        #expect(state.height == 180)
    }

    @Test func aSavedHeightBelowTheMinimumIsLifted() {
        store.set([10.0], forKey: "output.height")

        #expect(OutputPanelState(store: store, events: events).height == 120)
    }

    @Test func changesAreSaved() {
        let state = OutputPanelState(store: store, events: events)

        state.isVisible = true
        state.showsReads = true
        state.followsOutput = false

        #expect(store.bool(forKey: "output.visible"))
        #expect(store.bool(forKey: "output.showsReads"))
        #expect(store.string(forKey: "output.follows") == "off")
    }

    @Test func resizeClampsBetweenTheMinimumAndTheWindowRoomAndSaves() {
        let state = OutputPanelState(store: store, events: events)

        state.resize(to: 50, inWindowOfHeight: 820)
        #expect(state.height == 120)

        state.resize(to: 900, inWindowOfHeight: 820)
        #expect(state.height == 500)

        state.resize(to: 300.4, inWindowOfHeight: 820)
        #expect(state.height == 300)
        #expect(store.doubles(forKey: "output.height") == [300])
    }

    @Test func aSmallWindowCapsTheShownHeightWithoutChangingTheSavedOne() {
        let state = OutputPanelState(store: store, events: events)
        state.resize(to: 500, inWindowOfHeight: 900)

        #expect(state.height(inWindowOfHeight: 560) == 240)
        #expect(state.height(inWindowOfHeight: 400) == 120)
        #expect(state.height == 500)
    }

    @Test func resetHeightRestoresTheDefault() {
        let state = OutputPanelState(store: store, events: events)
        state.resize(to: 400, inWindowOfHeight: 820)

        state.resetHeight()

        #expect(state.height == 260)
        #expect(store.doubles(forKey: "output.height") == [260])
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
