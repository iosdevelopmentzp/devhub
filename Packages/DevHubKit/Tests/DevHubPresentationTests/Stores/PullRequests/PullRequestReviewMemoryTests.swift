import Foundation
import Testing
import DevHubDomain
import DevHubMocks
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct PullRequestReviewMemoryTests {
    private let harness = StoreHarness()

    private var memory: PullRequestReviewMemory {
        harness.pullRequestReviews
    }

    @Test func aReviewIsSavedPerProject() throws {
        memory.recordReview(of: 7, fingerprints: ["a.swift": "1"])

        let saved = try #require(harness.store.decode([String: ReviewSnapshot].self, forKey: PullRequestsPreferenceKeys.reviews(projectID: harness.session.selectedProjectID)))
        #expect(saved["7"]?.files == ["a.swift": "1"])
        #expect(saved["7"]?.reviewedAt == Date(timeIntervalSince1970: 1_800_000_000))
        #expect(memory.snapshot(of: 7)?.files == ["a.swift": "1"])
    }

    @Test func emptyFingerprintsAreNotAReview() {
        memory.recordReview(of: 7, fingerprints: [:])

        #expect(memory.snapshot(of: 7) == nil)
    }

    @Test func viewedMarksAreSaved() {
        memory.setViewed(true, path: "a.swift", fingerprint: "1", of: 7)

        #expect(memory.snapshot(of: 7)?.viewed == ["a.swift": "1"])
        #expect(memory.snapshot(of: 7)?.reviewedAt == nil)
    }

    @Test func forgetRemovesOneRequest() {
        memory.recordReview(of: 7, fingerprints: ["a.swift": "1"])
        memory.recordReview(of: 8, fingerprints: ["b.swift": "2"])

        memory.forget(7)

        #expect(memory.snapshot(of: 7) == nil)
        #expect(memory.snapshot(of: 8) != nil)
    }

    @Test func turnedOffItSavesAndShowsNothing() {
        memory.recordReview(of: 7, fingerprints: ["a.swift": "1"])
        harness.settings.values.remembersReviews = false

        memory.recordReview(of: 8, fingerprints: ["b.swift": "2"])

        #expect(memory.snapshot(of: 7) == nil)
        #expect(memory.snapshots["8"] == nil)
    }

    @Test func forgetAllClearsTheSavedReviews() {
        memory.recordReview(of: 7, fingerprints: ["a.swift": "1"])

        memory.forgetAll()

        #expect(memory.snapshots.isEmpty)
        #expect(harness.store.data(forKey: PullRequestsPreferenceKeys.reviews(projectID: harness.session.selectedProjectID)) == nil)
    }
}
