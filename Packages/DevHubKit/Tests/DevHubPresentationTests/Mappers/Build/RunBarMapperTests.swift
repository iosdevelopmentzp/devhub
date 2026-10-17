import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct RunBarMapperTests {
    @Test func idleWithoutTarget() {
        let model = map(state: BuildState(), target: nil, identity: nil, config: nil)

        #expect(model.targetLabel == "Target")
        #expect(model.target == nil)
        #expect(model.noTargetText == "No simulator selected")
        #expect(model.progress == nil)
        #expect(model.outcome == nil)
        #expect(model.isRunning == false)
        #expect(model.canRun == false)
    }

    @Test func runningShowsStepAndProgress() {
        var state = BuildState()
        state.phase = .running(step: "Compiling", progress: 0.4)

        let model = map(state: state, target: SimulatorFixture.iPhone, identity: nil, config: nil)

        #expect(model.progress == RunBarModel.Progress(step: "Compiling", value: 0.4))
        #expect(model.outcome == nil)
        #expect(model.isRunning)
        #expect(model.canRun)
    }

    @Test func runningWithoutProgressValue() {
        var state = BuildState()
        state.phase = .running(step: "Resolving", progress: nil)

        let model = map(state: state, target: nil, identity: nil, config: nil)

        #expect(model.progress == RunBarModel.Progress(step: "Resolving", value: nil))
    }

    @Test func succeededNamesTheTarget() throws {
        var state = BuildState()
        state.phase = .succeeded(.now)

        let withTarget = try #require(map(state: state, target: SimulatorFixture.iPhone, identity: nil, config: nil).outcome)
        let withoutTarget = try #require(map(state: state, target: nil, identity: nil, config: nil).outcome)

        #expect(withTarget.tint == .green)
        #expect(withTarget.text.hasPrefix("Launched on iPhone 16 Pro · "))
        #expect(withoutTarget.text.hasPrefix("Launched on simulator · "))
        #expect(map(state: state, target: nil, identity: nil, config: nil).progress == nil)
    }

    @Test func failedShowsTheMessageInRed() {
        var state = BuildState()
        state.phase = .failed("Build failed: 3 errors")

        let model = map(state: state, target: SimulatorFixture.iPhone, identity: nil, config: nil)

        #expect(model.outcome == RunBarModel.Outcome(tint: .red, text: "Build failed: 3 errors"))
        #expect(model.isRunning == false)
    }

    @Test func flagsFollowInputs() {
        let model = RunBarMapper.model(
            state: BuildState(),
            target: nil,
            runtime: nil,
            identity: nil,
            identitySettings: nil,
            savedDeviceIDs: [],
            deviceIDAliases: [:],
            mockState: nil,
            isApplying: false,
            config: nil,
            hasLog: true,
            isLoadingSimulators: true
        )

        #expect(model.canShowLog)
        #expect(model.canRefreshSimulators == false)
        #expect(map(state: BuildState(), target: nil, identity: nil, config: nil).canShowLog == false)
        #expect(map(state: BuildState(), target: nil, identity: nil, config: nil).canRefreshSimulators)
    }

    @Test func targetWithoutConfigHasNoIdentityParts() throws {
        let target = try #require(map(state: BuildState(), target: SimulatorFixture.iPad, identity: AppIdentityFixture.installed, config: nil).target)

        #expect(target.id == SimulatorFixture.iPad.id)
        #expect(target.name == "iPad Air")
        #expect(target.icon == "ipad")
        #expect(target.runtimeTag == TagModel("iOS 18.2"))
        #expect(target.identity == nil)
        #expect(target.identityMissingText == nil)
        #expect(target.launch == nil)
        #expect(target.cleanInstallNote == nil)
    }

    @Test func targetWithoutRuntimeHasNoRuntimeTag() throws {
        let model = RunBarMapper.model(
            state: BuildState(),
            target: SimulatorFixture.iPhone,
            runtime: nil,
            identity: nil,
            identitySettings: nil,
            savedDeviceIDs: [],
            deviceIDAliases: [:],
            mockState: nil,
            isApplying: false,
            config: nil,
            hasLog: false,
            isLoadingSimulators: false
        )

        let target = try #require(model.target)
        #expect(target.runtimeTag == nil)
        #expect(target.icon == "iphone")
    }

    @Test func targetWithConfigAndNoInstalledApp() throws {
        let target = try #require(map(state: BuildState(), target: SimulatorFixture.iPhone, identity: .notInstalled, config: AppIdentityFixture.config).target)

        #expect(target.identity == nil)
        #expect(target.identityMissingText == "App not installed on this simulator")
        #expect(target.launch == IdentityPanelMapper.launch(config: AppIdentityFixture.config, settings: SimulatorIdentitySettings(hasApplied: false), actualDeviceID: nil, savedDeviceIDs: [], aliases: [:]))
        #expect(target.cleanInstallNote == IdentityPanelMapper.cleanInstallNote(needsCleanInstall: false, cleanInstallIsOn: false))
    }

    @Test func targetWithConfigAndInstalledApp() throws {
        let settings = SimulatorIdentitySettings(hasApplied: false)
        let model = RunBarMapper.model(
            state: BuildState(),
            target: SimulatorFixture.iPhone,
            runtime: "iOS 18.2",
            identity: AppIdentityFixture.installed,
            identitySettings: settings,
            savedDeviceIDs: [],
            deviceIDAliases: [:],
            mockState: nil,
            isApplying: true,
            config: AppIdentityFixture.config,
            hasLog: false,
            isLoadingSimulators: false
        )

        let target = try #require(model.target)
        #expect(target.identity == IdentityPanelMapper.summary(for: AppIdentityFixture.installed, settings: settings, aliases: [:], mockState: nil, isApplying: true))
        #expect(target.identity?.isApplying == true)
        #expect(target.identityMissingText == nil)
    }

    @Test func cleanInstallStateTurnsTheNoteIntoAWarning() throws {
        var state = BuildState()
        let off = try #require(map(state: state, target: SimulatorFixture.iPhone, identity: AppIdentityFixture.fresh, config: AppIdentityFixture.config).target)
        state.cleanInstall = true

        let on = try #require(map(state: state, target: SimulatorFixture.iPhone, identity: AppIdentityFixture.fresh, config: AppIdentityFixture.config).target)

        #expect(off.cleanInstallNote?.icon == "info.circle")
        #expect(off.cleanInstallNote?.iconTint == .secondary)
        #expect(on.cleanInstallNote?.icon == "exclamationmark.triangle.fill")
        #expect(on.cleanInstallNote?.iconTint == .orange)
    }

    private func map(state: BuildState, target: Simulator?, identity: AppIdentity?, config: DeviceIdentityConfig?) -> RunBarModel {
        RunBarMapper.model(
            state: state,
            target: target,
            runtime: "iOS 18.2",
            identity: identity,
            identitySettings: nil,
            savedDeviceIDs: [],
            deviceIDAliases: [:],
            mockState: nil,
            isApplying: false,
            config: config,
            hasLog: false,
            isLoadingSimulators: false
        )
    }
}
