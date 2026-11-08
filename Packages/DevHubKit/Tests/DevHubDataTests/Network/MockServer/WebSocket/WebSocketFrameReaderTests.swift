import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct WebSocketFrameReaderTests {
    private func frame(opcode: UInt8, payload: [UInt8], isFinal: Bool = true, mask: [UInt8]? = nil) -> Data {
        var bytes: [UInt8] = [(isFinal ? 0x80 : 0) | opcode]
        let maskBit: UInt8 = mask == nil ? 0 : 0x80
        if payload.count < 126 {
            bytes.append(maskBit | UInt8(payload.count))
        } else if payload.count <= 0xFFFF {
            bytes += [maskBit | 126, UInt8(payload.count >> 8), UInt8(payload.count & 0xFF)]
        } else {
            bytes.append(maskBit | 127)
            bytes += (0..<8).reversed().map { UInt8((payload.count >> ($0 * 8)) & 0xFF) }
        }
        guard let mask else { return Data(bytes + payload) }
        return Data(bytes + mask + payload.enumerated().map { $0.element ^ mask[$0.offset % 4] })
    }

    @Test func readsMaskedAndPlainTextFrames() {
        var reader = WebSocketFrameReader()

        let sent = reader.append(frame(opcode: 0x1, payload: Array("40".utf8), mask: [1, 2, 3, 4]))
        let received = reader.append(frame(opcode: 0x1, payload: Array(#"42["balance"]"#.utf8)))

        #expect(sent == [.text("40")])
        #expect(received == [.text(#"42["balance"]"#)])
    }

    @Test func waitsForTheRestOfAFrameSplitAcrossChunks() {
        var reader = WebSocketFrameReader()
        let data = frame(opcode: 0x1, payload: Array(String(repeating: "x", count: 300).utf8))

        let first = reader.append(data.prefix(3))
        let second = reader.append(data.dropFirst(3))

        #expect(first.isEmpty)
        #expect(second == [.text(String(repeating: "x", count: 300))])
    }

    @Test func joinsFragmentsAndReadsControlFrames() {
        var reader = WebSocketFrameReader()
        var data = frame(opcode: 0x1, payload: Array("hel".utf8), isFinal: false)
        data += frame(opcode: 0x9, payload: [])
        data += frame(opcode: 0x0, payload: Array("lo".utf8))
        data += frame(opcode: 0x2, payload: [1, 2, 3])
        data += frame(opcode: 0x8, payload: [0x03, 0xE8])

        #expect(reader.append(data) == [.ping, .text("hello"), .binary(3), .close(1000)])
    }

    @Test func aLargeFrameIsCountedAndSkipped() {
        var reader = WebSocketFrameReader()
        let size = WebSocketFrameReader.maxPayload + 1
        var data = frame(opcode: 0x2, payload: [UInt8](repeating: 7, count: size))
        data += frame(opcode: 0x1, payload: Array("after".utf8))

        #expect(reader.append(data) == [.binary(size), .text("after")])
    }
}
