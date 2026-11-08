import Foundation

package protocol NetworkSourceRepository: Sendable {
    func follow(_ request: ScriptRunRequest) -> AsyncThrowingStream<NetworkSourceEvent, any Error>
}
