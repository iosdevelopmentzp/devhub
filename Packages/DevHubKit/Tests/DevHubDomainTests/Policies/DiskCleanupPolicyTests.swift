import Foundation
import Testing
@testable import DevHubDomain

@Suite struct DiskCleanupPolicyTests {
    private let roots = DiskCleanupPolicy.roots(home: URL(fileURLWithPath: "/Users/alex"), derivedDataRoot: URL(fileURLWithPath: "/Users/alex/Library/Developer/Xcode/DerivedData"))

    @Test func theRootsAreDerivedDataXcodeAndCaches() {
        #expect(roots == ["/Users/alex/Library/Developer/Xcode/DerivedData", "/Users/alex/Library/Developer/Xcode", "/Users/alex/Library/Caches"])
    }

    @Test func aPathInsideARootCanBeRemoved() {
        #expect(DiskCleanupPolicy.isRemovable("/Users/alex/Library/Developer/Xcode/DerivedData/ExampleApp-abc", roots: roots))
        #expect(DiskCleanupPolicy.isRemovable("/Users/alex/Library/Developer/Xcode/Archives/2026-10-01", roots: roots))
        #expect(DiskCleanupPolicy.isRemovable("/Users/alex/Library/Caches/CocoaPods", roots: roots))
    }

    @Test func aRootItselfAndPathsOutsideAreRefused() {
        #expect(DiskCleanupPolicy.isRemovable("/Users/alex/Library/Caches", roots: roots) == false)
        #expect(DiskCleanupPolicy.isRemovable("/Users/alex/Library/Caches/", roots: roots) == false)
        #expect(DiskCleanupPolicy.isRemovable("/Users/alex/Documents/example-app", roots: roots) == false)
        #expect(DiskCleanupPolicy.isRemovable("/Users/alex/Library/CachesOther/x", roots: roots) == false)
        #expect(DiskCleanupPolicy.isRemovable("relative/Library/Caches/x", roots: roots) == false)
    }

    @Test func aPathThatClimbsOutIsRefused() {
        #expect(DiskCleanupPolicy.isRemovable("/Users/alex/Library/Caches/../Mail", roots: roots) == false)
        #expect(DiskCleanupPolicy.isRemovable("/Users/alex/Library/Caches/x", roots: ["/"]) == false)
    }

    @Test func theTotalPrefersMeasuredSizes() {
        let items = [
            DiskCleanupItem(id: "a", kind: .archives, size: 10),
            DiskCleanupItem(id: "b", kind: .swiftPMCache),
            DiskCleanupItem(id: "c", kind: .simulatorRuntime, size: 5),
        ]

        #expect(DiskCleanupPolicy.totalSize(of: items, sizes: ["a": 30, "b": 7]) == 42)
    }
}
