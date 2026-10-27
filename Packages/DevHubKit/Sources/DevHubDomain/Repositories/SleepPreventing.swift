import Foundation

package protocol SleepPreventing: Sendable {
    func preventSleep(reason: String) throws
    func allowSleep()
}
