import Foundation

package struct GIFPlan: Hashable, Sendable {
    package var times: [Double]
    package var delay: Double
    package var width: Int
    package var height: Int

    package init(times: [Double], delay: Double, width: Int, height: Int) {
        self.times = times
        self.delay = delay
        self.width = width
        self.height = height
    }
}
