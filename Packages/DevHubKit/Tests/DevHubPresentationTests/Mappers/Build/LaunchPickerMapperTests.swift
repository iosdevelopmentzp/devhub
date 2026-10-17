import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation
import DevHubTestSupport

@Suite struct LaunchPickerMapperTests {
    private let booted = Simulator(id: "b", name: "iPhone 16", kind: .phone, state: .booted, isFavorite: false)
    private let favorite = Simulator(id: "f", name: "iPad Pro", kind: .pad, state: .shutdown, isFavorite: true)
    private let plain = Simulator(id: "p", name: "iPhone SE", kind: .phone, state: .shutdown, isFavorite: false)
    private let noSettings = SimulatorIdentitySettings(hasApplied: false)

    @Test func bootedThenFavoritesThenTheRestWithRuntimes() {
        let model = map(simulators: [plain, favorite, booted], config: nil)

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
        let model = map(simulators: [booted], config: .example)

        #expect(model.launch == IdentityPanelMapper.launch(config: .example, settings: noSettings, actualDeviceID: nil, savedDeviceIDs: [], aliases: [:]))
        #expect(model.cleanInstallNote == IdentityPanelMapper.cleanInstallNote(needsCleanInstall: false, cleanInstallIsOn: false))
    }

    @Test func cleanInstallChangesTheRunButton() {
        let model = map(simulators: [booted], config: .example, cleanInstallIsOn: true)

        #expect(model.runTitle == "Reinstall & Run")
        #expect(model.runTint == .orange)
    }

    @Test func cannotRunWithoutATargetOrDuringABuild() {
        #expect(map(simulators: [], config: nil, targetID: nil).canRun == false)
        #expect(map(simulators: [booted], config: nil, buildIsRunning: true).canRun == false)
    }

    private func map(
        simulators: [Simulator],
        config: DeviceIdentityConfig?,
        targetID: Simulator.ID? = "b",
        cleanInstallIsOn: Bool = false,
        buildIsRunning: Bool = false
    ) -> LaunchPickerModel {
        LaunchPickerMapper.model(
            subject: "feature/x",
            simulators: simulators,
            runtime: { _ in "iOS 18.2" },
            targetID: targetID,
            config: config,
            settings: noSettings,
            identity: nil,
            savedDeviceIDs: [],
            aliases: [:],
            cleanInstallIsOn: cleanInstallIsOn,
            buildIsRunning: buildIsRunning
        )
    }
}
