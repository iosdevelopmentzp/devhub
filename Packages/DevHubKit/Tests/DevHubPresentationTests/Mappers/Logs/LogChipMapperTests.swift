import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct LogChipMapperTests {
    @Test func chipsShowBootStateSelectionAndRunState() {
        var running = LogStream(id: SimulatorFixture.iPhone.id, name: "iPhone 16 Pro", process: "App", subsystem: "", minimumLevel: .debug)
        running.isRunning = true
        var failed = LogStream(id: "gone", name: "iPhone SE", process: "App", subsystem: "", minimumLevel: .debug)
        failed.error = "stopped"
        let idle = LogStream(id: "idle", name: "iPad", process: "App", subsystem: "", minimumLevel: .debug)
        let simulators = [SimulatorFixture.iPhone, Simulator(id: "idle", name: "iPad", kind: .pad, state: .shutdown, isFavorite: false)]

        let chips = LogChipMapper.models(streams: [running, failed, idle], selectedID: "gone", simulators: simulators)

        #expect(chips == [
            LogChipModel(id: SimulatorFixture.iPhone.id, title: "iPhone 16 Pro · booted", dotTint: .green, isSelected: false),
            LogChipModel(id: "gone", title: "iPhone SE · off", dotTint: .red, isSelected: true),
            LogChipModel(id: "idle", title: "iPad · off", dotTint: .secondary, isSelected: false)
        ])
    }

    @Test func addOptionsShowTheRuntimeWhenKnown() {
        let other = Simulator(id: "other", name: "iPhone SE", kind: .phone, state: .booted, isFavorite: false)

        let options = LogChipMapper.addOptions(available: [SimulatorFixture.iPhone, other]) { $0 == SimulatorFixture.iPhone.id ? "iOS 18.2" : nil }

        #expect(options == [
            LogChipMapper.Option(id: SimulatorFixture.iPhone.id, title: "iPhone 16 Pro · iOS 18.2"),
            LogChipMapper.Option(id: "other", title: "iPhone SE")
        ])
    }
}
