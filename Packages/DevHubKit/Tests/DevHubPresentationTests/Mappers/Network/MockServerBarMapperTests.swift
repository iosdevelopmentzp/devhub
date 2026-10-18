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
        let state = MockServerState(mode: .passthrough, setID: nil, upstreamHost: "api.staging.example.com", status: .running(port: 52001))

        let model = model(settings: MockSimulatorSettings(mode: .passthrough, setID: nil), state: state, isApplying: false, needsApply: false)

        #expect(model.statusText == "Port 52001 → api.staging.example.com")
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
        let model = MockServerBarMapper.model(settings: .off, state: nil, sets: [], hasSimulator: false, isApplying: false, needsApply: false, error: "boom", app: nil, report: nil, lastLaunch: nil, profiles: [])

        #expect(model.canApply == false)
        #expect(model.error == "boom")
    }

    @Test func appStatusExplainsWhetherTheAppUsesTheServer() {
        let profiles = IdentityContextFixture.profiles + [LaunchProfile(id: "dev", title: "Dev", upstream: "https://api.dev.example.com")]
        let running = MockServerState(mode: .passthrough, setID: nil, upstreamHost: "api.staging.example.com", status: .running(port: 52001))
        let app = IdentityContextFixture.installedApp
        let through = LaunchRecord(bundleID: nil, profileID: "staging", identity: nil, baseURL: "http://127.0.0.1:52001", date: .now)
        let oldPort = LaunchRecord(bundleID: nil, profileID: "staging", identity: nil, baseURL: "http://127.0.0.1:50000", date: .now)
        let noServer = LaunchRecord(bundleID: nil, profileID: "staging", identity: nil, baseURL: nil, date: .now)
        let otherProfile = LaunchRecord(bundleID: nil, profileID: "dev", identity: nil, baseURL: "http://127.0.0.1:52001", date: .now)
        let direct = AppStateReport(identity: nil, profile: nil, host: "api.staging.example.com", user: nil, version: nil)
        let local = AppStateReport(identity: nil, profile: nil, host: "127.0.0.1:52001", user: nil, version: nil)

        func status(_ state: MockServerState?, app: InstalledApp? = app, report: AppStateReport? = nil, lastLaunch: LaunchRecord?) -> (text: String, tint: Tint, hint: String)? {
            MockServerBarMapper.appStatus(state: state, app: app, report: report, lastLaunch: lastLaunch, profiles: profiles)
        }

        #expect(status(nil, lastLaunch: through) == nil)
        #expect(status(running, app: .notInstalled, lastLaunch: through)?.text == "App not installed on this simulator")
        #expect(status(running, lastLaunch: nil)?.text == "Launched outside DevHub: traffic may bypass the server")
        #expect(status(running, lastLaunch: oldPort)?.text == "App points to an old DevHub server (http://127.0.0.1:50000): relaunch")
        #expect(status(running, lastLaunch: noServer)?.text == "The last launch did not use the server: relaunch")
        #expect(status(running, report: direct, lastLaunch: through)?.text == "App reports api.staging.example.com: launched without DevHub")
        #expect(status(running, lastLaunch: otherProfile)?.text == "App is on Dev, the server forwards to Staging: relaunch")
        #expect(status(running, report: local, lastLaunch: through)?.tint == .green)
        #expect(status(running, app: nil, lastLaunch: through)?.text == "App goes through DevHub (http://127.0.0.1:52001)")
        #expect(model(settings: .off, state: nil, isApplying: false, needsApply: false).appText == nil)
    }

    private func model(settings: MockSimulatorSettings, state: MockServerState?, isApplying: Bool, needsApply: Bool) -> MockServerBarModel {
        MockServerBarMapper.model(settings: settings, state: state, sets: [set], hasSimulator: true, isApplying: isApplying, needsApply: needsApply, error: nil, app: nil, report: nil, lastLaunch: nil, profiles: [])
    }

    @Test func folderTextNamesTheDefaultOrTheConfiguredFolder() {
        #expect(MockServerBarMapper.folderText(for: .defaultFolder(project: "example-app")) == "~/.devhub/mocks/example-app")
        #expect(MockServerBarMapper.folderText(for: .folder("/repo/Mocks")) == "/repo/Mocks")
    }
}
