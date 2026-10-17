import Testing
@testable import DevHubUI

@Suite struct ByteFormatTests {
    @Test func formatsBytes() {
        #expect(ByteFormat.text(1_234_567_890).isEmpty == false)
    }

    @Test func formatsZeroBytes() {
        #expect(ByteFormat.text(0).isEmpty == false)
    }
}
