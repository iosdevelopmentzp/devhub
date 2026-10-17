import Foundation

nonisolated struct AttachNotice: Hashable, Sendable {
    var message: String
    var steps: String?
    var canRequestAccess: Bool
}
