import Foundation
import Testing
@testable import DevHubDomain

@Suite struct ReviewChangePolicyTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func file(_ path: String, _ lines: [String], kind: PullRequestFileDiff.Kind = .modified, isBinary: Bool = false) -> PullRequestFileDiff {
        PullRequestFileDiff(oldPath: path, path: path, kind: kind, additions: 1, deletions: 1, diff: GitDiff(lines: lines, droppedLines: 0, isBinary: isBinary), isTooLarge: false)
    }

    @Test func theFingerprintCountsOnlyAddedAndRemovedLines() {
        let first = file("a.swift", ["@@ -1,2 +1,2 @@", "-old", "+new", " context"])
        let moved = file("a.swift", ["@@ -10,2 +10,2 @@", "-old", "+new", " other context"])
        let edited = file("a.swift", ["@@ -1,2 +1,2 @@", "-old", "+newer", " context"])

        #expect(ReviewChangePolicy.fingerprint(of: first) == ReviewChangePolicy.fingerprint(of: moved))
        #expect(ReviewChangePolicy.fingerprint(of: first) != ReviewChangePolicy.fingerprint(of: edited))
    }

    @Test func theFingerprintIsStable() {
        #expect(ReviewChangePolicy.fingerprint(of: file("a.swift", ["+x"])) == "7e44607b4a8de76")
    }

    @Test func aBinaryFileUsesItsKindAndCounts() {
        #expect(ReviewChangePolicy.fingerprint(of: file("logo.png", [], kind: .added, isBinary: true)) == "added-1-1")
    }

    @Test func changedPathsAreTheNewAndTheEditedFilesInListOrder() {
        let reviewed = ReviewChangePolicy.reviewed(nil, fingerprints: ["a.swift": "1", "b.swift": "2"], at: date)

        let changed = ReviewChangePolicy.changedPaths(since: reviewed, paths: ["c.swift", "a.swift", "b.swift"], fingerprints: ["a.swift": "1", "b.swift": "3", "c.swift": "4"])

        #expect(changed == ["c.swift", "b.swift"])
    }

    @Test func nothingChangedWithoutAReview() {
        let viewedOnly = ReviewChangePolicy.settingViewed(true, path: "a.swift", fingerprint: "1", in: nil, at: date)

        #expect(ReviewChangePolicy.changedPaths(since: nil, paths: ["a.swift"], fingerprints: ["a.swift": "2"]).isEmpty)
        #expect(ReviewChangePolicy.changedPaths(since: viewedOnly, paths: ["a.swift"], fingerprints: ["a.swift": "2"]).isEmpty)
    }

    @Test func aViewedMarkLastsUntilTheFileChanges() {
        let snapshot = ReviewChangePolicy.settingViewed(true, path: "a.swift", fingerprint: "1", in: nil, at: date)

        #expect(ReviewChangePolicy.viewedPaths(in: snapshot, fingerprints: ["a.swift": "1", "b.swift": "2"]) == ["a.swift"])
        #expect(ReviewChangePolicy.viewedPaths(in: snapshot, fingerprints: ["a.swift": "9"]).isEmpty)
        #expect(ReviewChangePolicy.viewedPaths(in: ReviewChangePolicy.settingViewed(false, path: "a.swift", fingerprint: "1", in: snapshot, at: date), fingerprints: ["a.swift": "1"]).isEmpty)
    }

    @Test func aReviewKeepsTheViewedMarks() {
        let viewed = ReviewChangePolicy.settingViewed(true, path: "a.swift", fingerprint: "1", in: nil, at: date)

        let reviewed = ReviewChangePolicy.reviewed(viewed, fingerprints: ["a.swift": "1"], at: date)

        #expect(reviewed.reviewedAt == date)
        #expect(reviewed.viewed == ["a.swift": "1"])
        #expect(reviewed.files == ["a.swift": "1"])
    }

    @Test func everyFileViewedNeedsAtLeastOneFile() {
        #expect(ReviewChangePolicy.isEveryFileViewed(["a", "b"], paths: ["a", "b"]))
        #expect(ReviewChangePolicy.isEveryFileViewed(["a"], paths: ["a", "b"]) == false)
        #expect(ReviewChangePolicy.isEveryFileViewed([], paths: []) == false)
    }

    @Test func prunedKeepsTheNewestRequests() {
        let snapshots = Dictionary(uniqueKeysWithValues: (0...ReviewChangePolicy.requestLimit).map { index in
            (String(index), ReviewSnapshot(reviewedAt: nil, files: [:], viewed: [:], updatedAt: date.addingTimeInterval(Double(index))))
        })

        let pruned = ReviewChangePolicy.pruned(snapshots)

        #expect(pruned.count == ReviewChangePolicy.requestLimit)
        #expect(pruned["0"] == nil)
        #expect(pruned[String(ReviewChangePolicy.requestLimit)] != nil)
    }
}
