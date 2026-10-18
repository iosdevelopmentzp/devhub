import Foundation

package protocol AISessionRepository: Sendable {
    func sessions() async -> [AISession]
}
