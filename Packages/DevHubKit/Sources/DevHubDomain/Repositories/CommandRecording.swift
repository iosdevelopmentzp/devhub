import Foundation

package protocol CommandRecording: Sendable {
    func record(_ event: CommandEvent)
}
