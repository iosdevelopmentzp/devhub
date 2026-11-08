import Foundation
import DevHubDomain

struct WebSocketFrameReader {
    static let maxPayload = 1 << 20

    private var buffer: [UInt8] = []
    private var skipping = 0
    private var fragment: (opcode: UInt8, payload: [UInt8])?

    mutating func append(_ data: Data) -> [WebSocketMessage] {
        buffer.append(contentsOf: data)
        var messages: [WebSocketMessage] = []
        var offset = 0
        while true {
            if skipping > 0 {
                let count = min(skipping, buffer.count - offset)
                offset += count
                skipping -= count
                guard skipping == 0 else { break }
                continue
            }
            guard let header = Self.header(in: buffer, at: offset) else { break }
            if header.length > Self.maxPayload {
                offset += header.offset
                skipping = header.length
                messages.append(header.opcode == 0x1 ? .text("<\(header.length) bytes of text>") : .binary(header.length))
                continue
            }
            let start = offset + header.offset
            guard buffer.count >= start + header.length else { break }
            var payload = Array(buffer[start..<start + header.length])
            offset = start + header.length
            if let mask = header.mask {
                for index in payload.indices {
                    payload[index] ^= mask[index % 4]
                }
            }
            if let message = consume(opcode: header.opcode, isFinal: header.isFinal, payload: payload) {
                messages.append(message)
            }
        }
        buffer.removeFirst(offset)
        return messages
    }

    private mutating func consume(opcode: UInt8, isFinal: Bool, payload: [UInt8]) -> WebSocketMessage? {
        switch opcode {
        case 0x0:
            guard var open = fragment else { return nil }
            open.payload += payload
            guard isFinal else {
                fragment = open
                return nil
            }
            fragment = nil
            return Self.message(opcode: open.opcode, payload: open.payload)
        case 0x1, 0x2:
            guard isFinal else {
                fragment = (opcode, payload)
                return nil
            }
            return Self.message(opcode: opcode, payload: payload)
        case 0x8:
            return .close(payload.count >= 2 ? UInt16(payload[0]) << 8 | UInt16(payload[1]) : nil)
        case 0x9:
            return .ping
        case 0xA:
            return .pong
        default:
            return nil
        }
    }

    private static func message(opcode: UInt8, payload: [UInt8]) -> WebSocketMessage {
        guard opcode == 0x1 else { return .binary(payload.count) }
        return .text(String(decoding: payload, as: UTF8.self))
    }

    private static func header(in bytes: [UInt8], at start: Int) -> (isFinal: Bool, opcode: UInt8, length: Int, mask: [UInt8]?, offset: Int)? {
        let available = bytes.count - start
        guard available >= 2 else { return nil }
        let isFinal = bytes[start] & 0x80 != 0
        let opcode = bytes[start] & 0x0F
        let isMasked = bytes[start + 1] & 0x80 != 0
        var offset = 2
        var length = Int(bytes[start + 1] & 0x7F)
        if length == 126 {
            guard available >= 4 else { return nil }
            length = Int(bytes[start + 2]) << 8 | Int(bytes[start + 3])
            offset = 4
        } else if length == 127 {
            guard available >= 10 else { return nil }
            length = bytes[(start + 2)..<(start + 10)].reduce(0) { min($0 << 8 | Int($1), Int(Int32.max)) }
            offset = 10
        }
        var mask: [UInt8]?
        if isMasked {
            guard available >= offset + 4 else { return nil }
            mask = Array(bytes[(start + offset)..<(start + offset + 4)])
            offset += 4
        }
        return (isFinal, opcode, length, mask, offset)
    }
}
