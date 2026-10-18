import Foundation

package enum BuildEvent: Sendable {
    case step(String, progress: Double?)
    case output(String)
    case launched(LaunchRecord)
}
