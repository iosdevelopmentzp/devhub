import DevHubDomain
import DevHubMocks
import DevHubTestSupport
import Testing
@testable import DevHubPresentation

@Suite struct UtilsStoreTests {
    private let harness = StoreHarness()

    @Test func theFirstToolIsCompressVideo() {
        #expect(harness.utils.selection == .compressVideo)
    }

    @Test func aSavedToolIsRestored() {
        harness.store.set("compressVideo", forKey: "utils.selection")

        #expect(UtilsStore(store: harness.store).selection == .compressVideo)
    }

    @Test func anUnknownSavedToolFallsBackToTheFirst() {
        harness.store.set("removedTool", forKey: "utils.selection")

        #expect(UtilsStore(store: harness.store).selection == .compressVideo)
    }
}
