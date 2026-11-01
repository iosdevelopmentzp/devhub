import DevHubDomain
import DevHubMocks
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct SimulatorQAStoreTests {
    private let harness = StoreHarness()

    private var store: SimulatorQAStore {
        harness.simulatorQA
    }

    @Test func aSettingGoesToTheSimulatorAndIsLogged() async throws {
        store.apply(.appearance(.dark), to: SimulatorFixture.iPhone)
        #expect(store.isBusy(SimulatorFixture.iPhone.id))
        try await waitUntil { store.busyIDs.isEmpty }

        #expect(harness.spies.simulatorSettings.calls == [.apply(.appearance(.dark), udid: SimulatorFixture.iPhone.id)])
        #expect(harness.lastActivity?.title == "Dark appearance on iPhone 16 Pro")
        #expect(store.needsReboot.isEmpty)
    }

    @Test func aLanguageNeedsARebootUntilTheSimulatorShutsDown() async throws {
        store.apply(.language(code: "de", locale: "de_DE"), to: SimulatorFixture.iPhone)
        try await waitUntil { store.busyIDs.isEmpty }
        #expect(store.needsReboot == [SimulatorFixture.iPhone.id])

        store.rebooted(SimulatorFixture.iPhone.id)
        #expect(store.needsReboot.isEmpty)
    }

    @Test func aScreenshotGoesToTheFolderAndIsRemembered() async throws {
        store.screenshot(SimulatorFixture.iPhone)
        try await waitUntil { store.busyIDs.isEmpty }

        let path = "/tmp/DevHubTests/Shots/iPhone 16 Pro 2027-01-15 080000.png"
        #expect(harness.spies.simulatorSettings.calls == [.screenshot(udid: SimulatorFixture.iPhone.id, path: path, cutsCorners: false)])
        #expect(store.screenshots[SimulatorFixture.iPhone.id] == path)
    }

    @Test func aFailureIsLoggedAndNothingIsRemembered() async throws {
        harness.spies.simulatorSettings.error = SimulatorError.command("not booted")

        store.screenshot(SimulatorFixture.iPhone)
        try await waitUntil { store.busyIDs.isEmpty }

        #expect(harness.lastActivity?.outcome == .failure)
        #expect(store.screenshots.isEmpty)
    }

    @Test func aFramedScreenshotCutsTheCornersThenAddsTheFrame() async throws {
        store.addsDeviceFrame = true

        store.screenshot(SimulatorFixture.iPhone)
        try await waitUntil { store.busyIDs.isEmpty }

        let path = "/tmp/DevHubTests/Shots/iPhone 16 Pro 2027-01-15 080000.png"
        #expect(harness.spies.simulatorSettings.calls == [.screenshot(udid: SimulatorFixture.iPhone.id, path: path, cutsCorners: true)])
        #expect(harness.spies.media.calls == [.addFrame(screenshot: path, udid: SimulatorFixture.iPhone.id)])
        #expect(store.screenshots[SimulatorFixture.iPhone.id] == path)
        #expect(harness.lastActivity?.detail == "With the device frame")
    }

    @Test func aMissingFrameKeepsThePlainScreenshot() async throws {
        store.addsDeviceFrame = true
        harness.spies.media.frameError = MediaError.noFrame("Xcode has no frame phone11.")

        store.screenshot(SimulatorFixture.iPhone)
        try await waitUntil { store.busyIDs.isEmpty }

        #expect(store.screenshots[SimulatorFixture.iPhone.id] != nil)
        #expect(harness.lastActivity?.title == "Screenshot of iPhone 16 Pro has no frame")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func theFrameChoiceIsSaved() {
        store.addsDeviceFrame = true

        #expect(harness.store.bool(forKey: "simulatorQA.addsDeviceFrame"))
    }

    @Test func aRecordingRunsUntilStopThenIsRemembered() async throws {
        let id = SimulatorFixture.iPhone.id
        store.startRecording(SimulatorFixture.iPhone)
        try await waitUntil { store.recordingStarts[id] != nil }

        let path = "/tmp/DevHubTests/Shots/iPhone 16 Pro 2027-01-15 080000.mov"
        #expect(harness.spies.simulatorSettings.calls == [.record(udid: id, path: path)])
        #expect(store.isRecording(id))
        #expect(harness.operations.latest(at: .simulator(id))?.status == .running)

        store.stopRecording(id)
        try await waitUntil { store.isRecording(id) == false }

        #expect(store.recordings[id] == path)
        #expect(store.recordingStarts.isEmpty)
        #expect(harness.operations.latest(at: .simulator(id))?.status == .succeeded)
        #expect(harness.lastActivity?.title == "Recorded iPhone 16 Pro")
    }

    @Test func aRecordingThatEndsByItselfIsKept() async throws {
        let id = SimulatorFixture.iPhone.id
        store.startRecording(SimulatorFixture.iPhone)
        try await waitUntil { store.recordingStarts[id] != nil }

        harness.spies.simulatorSettings.finishRecordings()
        try await waitUntil { store.isRecording(id) == false }

        #expect(store.recordings[id] != nil)
    }

    @Test func aSecondStartWhileRecordingDoesNothing() async throws {
        let id = SimulatorFixture.iPhone.id
        store.startRecording(SimulatorFixture.iPhone)
        try await waitUntil { store.recordingStarts[id] != nil }

        store.startRecording(SimulatorFixture.iPhone)
        store.stopRecording(id)
        try await waitUntil { store.isRecording(id) == false }

        #expect(harness.spies.simulatorSettings.calls.count == 1)
    }

    @Test func aFailedRecordingFailsTheOperation() async throws {
        let id = SimulatorFixture.iPhone.id
        harness.spies.simulatorSettings.error = SimulatorError.command("not booted")

        store.startRecording(SimulatorFixture.iPhone)
        try await waitUntil { store.isRecording(id) == false }

        #expect(store.recordings.isEmpty)
        #expect(harness.operations.latest(at: .simulator(id))?.status == .failed("not booted"))
        #expect(harness.lastActivity?.title == "Recording of iPhone 16 Pro failed")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func quittingStopsEveryRecording() async throws {
        store.startRecording(SimulatorFixture.iPhone)
        store.startRecording(SimulatorFixture.iPad)
        try await waitUntil { store.recordingStarts.count == 2 }

        store.stopAllRecordings()
        try await waitUntil { store.recordingIDs.isEmpty }

        #expect(store.recordings.count == 2)
    }
}
