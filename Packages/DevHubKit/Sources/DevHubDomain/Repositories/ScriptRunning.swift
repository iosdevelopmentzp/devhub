import Foundation

package protocol ScriptRunning: Sendable {
    func run(_ request: ScriptRunRequest) -> AsyncThrowingStream<ScriptEvent, any Error>
}
