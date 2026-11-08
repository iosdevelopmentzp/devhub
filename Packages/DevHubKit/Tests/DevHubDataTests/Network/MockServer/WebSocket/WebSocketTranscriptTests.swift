import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct WebSocketTranscriptTests {
    @Test func linesShowTheDirectionAndSkipPings() {
        var transcript = WebSocketTranscript()

        transcript.add(.text("40"), isSent: true)
        transcript.add(.ping, isSent: false)
        transcript.add(.binary(12), isSent: false)
        transcript.add(.close(1000), isSent: false)

        #expect(transcript.text == "→ 40\n← <12 bytes of binary data>\n← close 1000")
    }

    @Test func onlyTheNewestLinesAreKept() {
        var transcript = WebSocketTranscript()

        for index in 0..<(WebSocketTranscript.maxLines + 2) {
            transcript.add(.text("m\(index)"), isSent: false)
        }

        #expect(transcript.lines.count == WebSocketTranscript.maxLines)
        #expect(transcript.text.hasPrefix("… 2 earlier messages are not shown\n← m2\n"))
    }
}
