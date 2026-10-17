import Foundation

package enum FetchPolicy {

    package static func shouldFetch(lastFetch: Date?, everyMinutes minutes: Int, now: Date) -> Bool {
        guard minutes > 0 else { return false }
        guard let lastFetch else { return true }
        return now.timeIntervalSince(lastFetch) >= TimeInterval(minutes * 60)
    }
}
