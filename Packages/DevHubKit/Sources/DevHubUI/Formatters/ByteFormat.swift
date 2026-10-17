import Foundation

package nonisolated enum ByteFormat {

    package static func text(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
