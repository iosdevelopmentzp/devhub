import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation
import DevHubTestSupport

@Suite struct MockServerBarMapperTests {
    private let set = MockSet(id: UUID(), name: "VIP", rules: [MockRuleFactory.newRule(id: UUID())])

    @Test func offWithoutServerCanApplyAndHidesTheSetPicker() {
        let model = model(settings: .off, state: nil, isApplying: false, needsApply: false)

        #expect(model.mode == .off)
        #expect(model.modes.map(\.title) == ["Off", "Passthrough", "Mock"])
        #expect(model.showsSetPicker == false)
        #expect(model.canApply)
        #expect(model.isApplyProminent == false)
        #expect(model.statusText == "Server off")
        #expect(model.statusTint == .secondary)
    }

    @Test func mockModeNeedsAnExistingSet() {
        let without = model(settings: MockSimulatorSettings(mode: .mock, setID: nil), state: nil, isApplying: false, needsApply: true)
        let with = model(settings: MockSimulatorSettings(mode: .mock, setID: set.id), state: nil, isApplying: false, needsApply: true)

        #expect(without.showsSetPicker)
        #expect(without.canApply == false)
        #expect(without.selectedSetID == nil)
        #expect(with.canApply)
        #expect(with.selectedSetID == set.id)
        #expect(with.sets.map(\.title) == ["VIP · 1 rule"])
        #expect(with.isApplyProminent)
    }

    @Test func runningServerShowsPortAndHost() {
        let state = MockServerState(mode: .passthrough, setID: nil, upstreamHost: "api-qa.example.com", status: .running(port: 52001))

        let model = model(settings: MockSimulatorSettings(mode: .passthrough, setID: nil), state: state, isApplying: false, needsApply: false)

        #expect(model.statusText == "Port 52001 → api-qa.example.com")
        #expect(model.statusTint == .green)
        #expect(model.statusHint.contains("http://127.0.0.1:52001"))
    }

    @Test func applyingDisablesTheButtonAndShowsProgress() {
        let model = model(settings: MockSimulatorSettings(mode: .passthrough, setID: nil), state: nil, isApplying: true, needsApply: true)

        #expect(model.applyTitle == "Relaunching…")
        #expect(model.canApply == false)
        #expect(model.isApplyProminent == false)
        #expect(model.statusTint == .orange)
    }

    @Test func noSimulatorCannotApplyAndErrorsPassThrough() {
        let model = MockServerBarMapper.model(settings: .off, state: nil, sets: [], hasSimulator: false, isApplying: false, needsApply: false, error: "boom", identity: nil, config: nil)

        #expect(model.canApply == false)
        #expect(model.error == "boom")
    }

    @Test func appStatusExplainsWhetherTheAppUsesTheServer() {
        let running = MockServerState(mode: .passthrough, setID: nil, upstreamHost: "api-qa.example.com", status: .running(port: 52001))
        let through = AppIdentity(isInstalled: true, version: "1", hasDebugHooks: true, storedEnvironment: "qa", apiHost: "127.0.0.1:52001")
        let direct = AppIdentity(isInstalled: true, version: "1", hasDebugHooks: true, storedEnvironment: "qa", apiHost: "api-qa.example.com")
        let otherEnvironment = AppIdentity(isInstalled: true, version: "1", hasDebugHooks: true, storedEnvironment: "dev", apiHost: "127.0.0.1:52001")
        let silent = AppIdentity(isInstalled: true, version: "1", hasDebugHooks: true)

        #expect(MockServerBarMapper.appStatus(state: nil, identity: through, config: .example) == nil)
        #expect(MockServerBarMapper.appStatus(state: running, identity: .notInstalled, config: .example)?.text == "App not installed on this simulator")
        #expect(MockServerBarMapper.appStatus(state: running, identity: silent, config: .example)?.text == "App has not sent requests yet")
        #expect(MockServerBarMapper.appStatus(state: running, identity: through, config: .example)?.tint == .green)
        #expect(MockServerBarMapper.appStatus(state: running, identity: direct, config: .example)?.text == "App talks to api-qa.example.com directly: launched without DevHub")
        #expect(MockServerBarMapper.appStatus(state: running, identity: otherEnvironment, config: .example)?.text == "App is on dev, the server forwards to qa: relaunch")
        #expect(model(settings: .off, state: nil, isApplying: false, needsApply: false).appText == nil)
    }

    private func model(settings: MockSimulatorSettings, state: MockServerState?, isApplying: Bool, needsApply: Bool) -> MockServerBarModel {
        MockServerBarMapper.model(settings: settings, state: state, sets: [set], hasSimulator: true, isApplying: isApplying, needsApply: needsApply, error: nil, identity: nil, config: nil)
    }
}
