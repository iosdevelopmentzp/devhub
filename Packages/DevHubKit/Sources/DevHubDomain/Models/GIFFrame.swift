import Foundation

package struct GIFFrame: Hashable, Sendable {
    package var sample: Int
    package var delay: Double

    package init(sample: Int, delay: Double) {
        self.sample = sample
        self.delay = delay
    }
}
