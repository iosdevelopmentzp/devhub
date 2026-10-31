import Foundation

package struct CommandEvent: Sendable {
    package enum Payload: Sendable {
        case started(command: String, cwd: String?, kind: CommandKind, operationID: UUID?)
        case output([String])
        case finished(exitCode: Int32?, error: String?)
    }

    package let id: UUID
    package let payload: Payload

    package init(id: UUID, payload: Payload) {
        self.id = id
        self.payload = payload
    }
}
