import Foundation

struct BuildStepThrottle {
    let interval: Duration
    private var lastEmit: ContinuousClock.Instant?

    init(interval: Duration) {
        self.interval = interval
    }

    mutating func shouldEmit(at now: ContinuousClock.Instant) -> Bool {
        if let lastEmit, now - lastEmit < interval {
            return false
        }
        lastEmit = now
        return true
    }
}
