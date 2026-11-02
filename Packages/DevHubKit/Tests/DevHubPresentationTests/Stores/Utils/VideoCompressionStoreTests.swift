import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct VideoCompressionStoreTests {
    private let harness = StoreHarness()
    private let first = "/Users/alex/Desktop/Screen Recording.mov"
    private let second = "/Users/alex/Desktop/ABC-123 bug.mp4"

    private var store: VideoCompressionStore {
        harness.videoCompression
    }

    private var spy: SpyVideoCompressionRepository {
        harness.spies.videoCompression
    }

    // MARK: Engine

    @Test func checkingTheEngineKeepsItsStatus() async {
        spy.engineStatusResult = .missing(homebrewPath: "/opt/homebrew/bin/brew")

        await store.checkEngine()

        #expect(store.engine == .missing(homebrewPath: "/opt/homebrew/bin/brew"))
        #expect(store.isEngineReady == false)
        #expect(spy.calls == [.engineStatus])
    }

    @Test func anInstallShowsTheStepsThenTheReadyEngine() async throws {
        spy.engineStatusResult = .missing(homebrewPath: "/opt/homebrew/bin/brew")
        spy.engineStatusAfterInstall = .ready(version: "9.0.2", path: "/opt/homebrew/bin/ffmpeg")
        await store.checkEngine()

        store.installEngine()

        #expect(store.install.isRunning)
        try await waitUntil { store.isEngineReady }
        #expect(store.install == .idle)
        #expect(spy.calls == [.engineStatus, .installEngine, .engineStatus])
        #expect(harness.activityTitles.contains("Installed ffmpeg"))
    }

    @Test func aFailedInstallKeepsTheReason() async throws {
        spy.engineStatusResult = .missing(homebrewPath: "/opt/homebrew/bin/brew")
        spy.installError = VideoCompressionError.installFailed("Cannot write to /opt/homebrew/Cellar")

        store.installEngine()

        try await waitUntil { store.install.isRunning == false }
        #expect(store.install == .failed("brew install ffmpeg failed: Cannot write to /opt/homebrew/Cellar"))
        #expect(harness.lastActivity?.title == "Could not install ffmpeg")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    // MARK: Queue

    @Test func droppedVideosAreCompressedOneByOneNextToTheOriginal() async throws {
        await store.checkEngine()

        store.add(paths: [first, second])

        try await waitUntil { store.jobs.allSatisfy(\.isFinished) }
        #expect(spy.calls == [
            .engineStatus,
            .info(path: first), .compress(path: first, settings: .standard),
            .info(path: second), .compress(path: second, settings: .standard),
        ])
        guard case .done(let result, _) = store.jobs[0].state else {
            Issue.record("Expected a finished job, got \(store.jobs[0].state)")
            return
        }
        #expect(result.path == "/Users/alex/Desktop/Screen Recording compressed.mp4")
        #expect(store.jobs[0].info == SpyVideoCompressionRepository.sampleInfo)
        #expect(harness.activityTitles.contains("Compressed Screen Recording.mov"))
    }

    @Test func theFirstDropChecksTheEngineThenStarts() async throws {
        store.add(paths: [first])

        try await waitUntil { store.jobs.first?.isFinished == true }
        #expect(spy.calls.first == .engineStatus)
        #expect(spy.calls.contains(.compress(path: first, settings: .standard)))
    }

    @Test func aFileThatIsNotAVideoIsRefused() async {
        await store.checkEngine()

        store.add(paths: ["/Users/alex/Desktop/notes.txt"])

        #expect(store.jobs.isEmpty)
        #expect(harness.lastActivity?.title == "Cannot compress notes.txt")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func aVideoThatIsAlreadyQueuedIsNotAddedAgain() async {
        spy.engineStatusResult = .missing(homebrewPath: nil)
        await store.checkEngine()

        store.add(paths: [first])
        store.add(paths: [first])

        #expect(store.jobs.count == 1)
    }

    @Test func videosWaitForTheEngineAndStartAfterTheInstall() async throws {
        spy.engineStatusResult = .missing(homebrewPath: "/opt/homebrew/bin/brew")
        spy.engineStatusAfterInstall = .ready(version: "9.0.2", path: "/opt/homebrew/bin/ffmpeg")
        await store.checkEngine()
        store.add(paths: [first])
        await harness.settle()
        #expect(store.jobs.map(\.state) == [.waiting])

        store.installEngine()

        try await waitUntil { store.jobs.first?.isFinished == true }
        #expect(spy.calls.contains(.compress(path: first, settings: .standard)))
    }

    @Test func theChosenQualityGoesWithTheVideo() async throws {
        await store.checkEngine()
        store.settings = VideoCompressionSettings(quality: .small, keepsAudio: false)

        store.add(paths: [first])

        try await waitUntil { store.jobs.first?.isFinished == true }
        #expect(spy.calls.contains(.compress(path: first, settings: VideoCompressionSettings(quality: .small, keepsAudio: false))))
    }

    @Test func aFailedVideoKeepsTheReasonAndTheNextOneStillRuns() async throws {
        await store.checkEngine()
        spy.infoResult = .failure(VideoCompressionError.unreadable("Screen Recording.mov", reason: "Invalid data found when processing input"))

        store.add(paths: [first, second])

        try await waitUntil { store.jobs.allSatisfy(\.isFinished) }
        #expect(store.jobs.count == 2)
        #expect(store.jobs[0].state == .failed("Cannot read Screen Recording.mov: Invalid data found when processing input"))
        #expect(spy.calls == [.engineStatus, .info(path: first), .info(path: second)])
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func stopEndsTheRunningVideoWithoutAFile() async throws {
        await store.checkEngine()
        spy.compressHold = .seconds(30)
        store.add(paths: [first])
        try await waitUntil { store.jobs.first.map { if case .compressing = $0.state { true } else { false } } == true }

        store.stop(store.jobs[0].id)

        try await waitUntil { store.jobs.first?.state == .stopped }
        #expect(harness.lastActivity?.title == "Stopped compressing Screen Recording.mov")
    }

    @Test func stopTakesAWaitingVideoOutOfTheQueue() async {
        spy.engineStatusResult = .missing(homebrewPath: nil)
        await store.checkEngine()
        store.add(paths: [first])

        store.stop(store.jobs[0].id)

        #expect(store.jobs[0].state == .stopped)
        #expect(spy.calls == [.engineStatus])
    }

    @Test func compressAgainQueuesTheSameVideoWithTheCurrentQuality() async throws {
        await store.checkEngine()
        store.add(paths: [first])
        try await waitUntil { store.jobs.first?.isFinished == true }
        store.settings = VideoCompressionSettings(quality: .high, keepsAudio: true)

        store.compressAgain(store.jobs[0].id)

        try await waitUntil { store.jobs.count == 2 && store.jobs.allSatisfy(\.isFinished) }
        #expect(spy.calls.last == .compress(path: first, settings: VideoCompressionSettings(quality: .high, keepsAudio: true)))
    }

    @Test func clearFinishedKeepsOnlyTheWaitingVideos() async {
        spy.engineStatusResult = .missing(homebrewPath: nil)
        await store.checkEngine()
        store.add(paths: [first, second])
        store.stop(store.jobs[0].id)

        store.clearFinished()

        #expect(store.jobs.map(\.source) == [second])
        #expect(store.hasFinishedJobs == false)
    }

    @Test func removeTakesARowAway() async {
        spy.engineStatusResult = .missing(homebrewPath: nil)
        await store.checkEngine()
        store.add(paths: [first])

        store.remove(store.jobs[0].id)

        #expect(store.jobs.isEmpty)
    }

    // MARK: Settings

    @Test func theSettingsAreSavedAndRestored() {
        store.settings = VideoCompressionSettings(quality: .high, keepsAudio: false)

        let restored = VideoCompressionStore(repository: spy, store: harness.store, activity: harness.activity, notifier: harness.notifier, toaster: harness.toaster, now: { .now })

        #expect(restored.settings == VideoCompressionSettings(quality: .high, keepsAudio: false))
    }

    @Test func theDefaultSettingsAreBalancedWithSound() {
        #expect(store.settings == .standard)
    }
}
