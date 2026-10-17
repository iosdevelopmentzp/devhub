import Foundation
import DevHubDomain

@MainActor
protocol GitLabRemoteLookup: AnyObject {
    func gitLabURL() async throws -> URL
}
