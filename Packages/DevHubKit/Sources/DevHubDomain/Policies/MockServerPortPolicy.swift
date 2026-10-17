import Foundation

package enum MockServerPortPolicy {
    package static let firstPort = 49_152
    package static let portCount = 10_000

    package static func port(for udid: String) -> Int {
        var hash: UInt32 = 2_166_136_261
        for byte in udid.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16_777_619
        }
        return firstPort + Int(hash % UInt32(portCount))
    }
}
