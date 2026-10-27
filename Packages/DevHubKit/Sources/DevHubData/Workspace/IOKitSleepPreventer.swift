import Foundation
import DevHubDomain
import IOKit.pwr_mgt

final class IOKitSleepPreventer: SleepPreventing, @unchecked Sendable {
    private let lock = NSLock()
    private var assertionID: IOPMAssertionID?

    func preventSleep(reason: String) throws {
        try lock.withLock {
            guard assertionID == nil else { return }
            var id = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason as CFString,
                &id
            )
            guard result == kIOReturnSuccess else {
                throw SleepPreventionError.assertionFailed(result)
            }
            assertionID = id
        }
    }

    func allowSleep() {
        lock.withLock {
            guard let assertionID else { return }
            IOPMAssertionRelease(assertionID)
            self.assertionID = nil
        }
    }
}
