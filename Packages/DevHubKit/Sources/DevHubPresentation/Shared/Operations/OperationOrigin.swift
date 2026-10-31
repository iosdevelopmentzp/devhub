import Foundation

struct OperationOrigin: Hashable {
    let key: String

    static let git = OperationOrigin(key: "git")
    static let changes = OperationOrigin(key: "changes")
    static let simulators = OperationOrigin(key: "simulators")
    static let messaging = OperationOrigin(key: "messaging")

    static func action(_ id: String) -> OperationOrigin {
        OperationOrigin(key: "action:" + id)
    }
}
