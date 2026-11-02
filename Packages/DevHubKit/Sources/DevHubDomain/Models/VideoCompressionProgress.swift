import Foundation

package struct VideoCompressionProgress: Hashable, Sendable {
    package var seconds: Double
    package var speed: Double?

    package init(seconds: Double, speed: Double?) {
        self.seconds = seconds
        self.speed = speed
    }
}
