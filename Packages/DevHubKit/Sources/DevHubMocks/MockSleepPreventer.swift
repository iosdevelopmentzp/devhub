import Foundation
import DevHubDomain

struct MockSleepPreventer: SleepPreventing {

    func preventSleep(reason: String) throws {}

    func allowSleep() {}
}
