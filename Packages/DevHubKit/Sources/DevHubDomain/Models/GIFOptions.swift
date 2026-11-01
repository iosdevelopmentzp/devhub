import Foundation

package struct GIFOptions: Hashable, Sendable {
    package var width: Int
    package var framesPerSecond: Int

    package init(width: Int, framesPerSecond: Int) {
        self.width = width
        self.framesPerSecond = framesPerSecond
    }
}
