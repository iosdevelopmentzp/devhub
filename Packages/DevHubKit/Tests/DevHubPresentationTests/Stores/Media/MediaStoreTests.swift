import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct MediaStoreTests {
    private let harness = StoreHarness()
    private let origin = OperationOrigin.simulator("U1")
    private let source = "/Users/alex/Desktop/iPhone 2027.mov"

    private var store: MediaStore {
        harness.media
    }

    @Test func aGIFRunsAsAnOperationAndRemembersTheFile() async throws {
        store.convert(source, to: .mediumGIF, framedFor: nil, at: origin)
        #expect(store.isBusy(source))
        try await waitUntil { store.busySources.isEmpty }

        #expect(harness.spies.media.calls == [.makeGIF(source: source, options: GIFOptions(width: 480, framesPerSecond: 15), framedFor: nil)])
        #expect(store.outputs[origin] == "/Users/alex/Desktop/iPhone 2027.gif")
        #expect(harness.operations.latest(at: origin)?.status == .succeeded)
        #expect(harness.lastActivity?.title == "GIF from iPhone 2027.mov")
    }

    @Test func aCompressionUsesTheChosenQualityAndFrame() async throws {
        store.convert(source, to: .hevcAt1080p, framedFor: "U1", at: origin)
        try await waitUntil { store.busySources.isEmpty }

        #expect(harness.spies.media.calls == [.compress(source: source, compression: .hevcAt1080p, framedFor: "U1")])
        #expect(store.outputs[origin] == "/Users/alex/Desktop/iPhone 2027 framed HEVC 1080p.mp4")
    }

    @Test func aFileThatIsNotAVideoIsRefused() {
        store.convert("/Users/alex/Desktop/shot.png", to: .smallGIF, framedFor: nil, at: origin)

        #expect(harness.spies.media.calls.isEmpty)
        #expect(harness.lastActivity?.title == "Cannot convert shot.png")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func aFailureFailsTheOperation() async throws {
        harness.spies.media.error = MediaError.noVideo(source)

        store.convert(source, to: .smallGIF, framedFor: nil, at: origin)
        try await waitUntil { store.busySources.isEmpty }

        #expect(store.outputs.isEmpty)
        #expect(harness.operations.latest(at: origin)?.status == .failed("iPhone 2027.mov has no video track."))
        #expect(harness.lastActivity?.outcome == .failure)
    }
}
