import Foundation

package struct VideoCompressionResult: Hashable, Sendable {
    package var path: String
    package var size: Int64

    package init(path: String, size: Int64) {
        self.path = path
        self.size = size
    }
}
