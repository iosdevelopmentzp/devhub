import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation
import DevHubTestSupport

@Suite struct LaunchPickerMapperTests {
    private let booted = Simulator(id: "b", name: "iPhone 16", kind: .phone, state: .booted, isFavorite: false)
    private let favorite = Simulator(id: "f", name: "iPad Pro", kind: .pad, state: .shutdown, isFavorite: true)
    private let plain = Simulator(id: "p", name: "iPhone SE", kind: .phone, state: .shutdown, isFavorite: false)
    private let context = IdentityContextFixture.context()

    @Test func bootedThenFavoritesThenTheRestWithRuntimes() {
        let model = map(simulators: [plain, favorite, booted], identity: nil)

        #expect(model.simulators == [
            LaunchPickerModel.SimulatorOption(id: "b", title: "iPhone 16 · iOS 18.2 · booted"),
            LaunchPickerModel.SimulatorOption(id: "f", title: "iPad Pro · iOS 18.2"),
            LaunchPickerModel.SimulatorOption(id: "p", title: "iPhone SE · iOS 18.2"),
        ])
        #expect(model.title == "Build & Run feature/x on")
        #expect(model.selectedID == "b")
        #expect(model.launch == nil)
        #expect(model.cleanInstallNote == nil)
        #expect(model.runTitle == "Build & Run")
        #expect(model.runTint == .green)
        #expect(model.canRun)
    }

    @Test func withAConfigTheIdentityControlsAndTheNoteAppear() {
        let model = map(simulators: [booted], identity: context)

        #expect(model.launch == IdentityPanelMapper.launch(context: context))
        #expect(model.cleanInstallNote == IdentityPanelMapper.cleanInstallNote(context: context, cleanInstallIsOn: false))
    }

    @Test func cleanInstallChangesTheRunButton() {
        let model = map(simulators: [booted], identity: context, cleanInstallIsOn: true)

        #expect(model.runTitle == "Reinstall & Run")
        #expect(model.runTint == .orange)
    }

    @Test func anotherIDChangesTheRunButton() {
        let other = IdentityContextFixture.context(settings: IdentityContextFixture.settings(desired: "devhub-1"))

        #expect(map(simulators: [booted], identity: other).runTitle == "Reinstall & Run")
    }

    @Test func cannotRunWithoutATargetOrDuringABuild() {
        #expect(map(simulators: [], identity: nil, targetID: nil).canRun == false)
        #expect(map(simulators: [booted], identity: nil, buildIsRunning: true).canRun == false)
    }

    private func map(
        simulators: [Simulator],
        identity: IdentityContext?,
        targetID: Simulator.ID? = "b",
        cleanInstallIsOn: Bool = false,
        buildIsRunning: Bool = false
    ) -> LaunchPickerModel {
        LaunchPickerMapper.model(
            subject: "feature/x",
            simulators: simulators,
            runtime: { _ in "iOS 18.2" },
            targetID: targetID,
            identity: identity,
            cleanInstallIsOn: cleanInstallIsOn,
            buildIsRunning: buildIsRunning
        )
    }
}
