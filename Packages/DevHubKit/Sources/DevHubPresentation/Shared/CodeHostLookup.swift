import Foundation
import DevHubDomain

@MainActor
protocol CodeHostLookup: AnyObject {
    var remoteName: String { get }
    func codeHost() async throws -> CodeHost
}
