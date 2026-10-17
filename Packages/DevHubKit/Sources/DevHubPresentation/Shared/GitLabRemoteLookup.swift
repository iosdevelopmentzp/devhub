import Foundation
import DevHubDomain

@MainActor
protocol GitLabRemoteLookup: AnyObject {
    var remoteName: String { get }
    func gitLabURL() async throws -> URL
}
