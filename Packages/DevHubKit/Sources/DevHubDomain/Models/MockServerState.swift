import Foundation

package struct MockServerState: Hashable, Sendable {
    package enum Status: Hashable, Sendable {
        case running(port: Int)
        case failed(String)
    }

    package var mode: MockMode
    package var setID: MockSet.ID?
    package var upstreamHost: String
    package var status: Status

    package init(mode: MockMode, setID: MockSet.ID?, upstreamHost: String, status: Status) {
        self.mode = mode
        self.setID = setID
        self.upstreamHost = upstreamHost
        self.status = status
    }

    package var port: Int? {
        guard case .running(let port) = status else { return nil }
        return port
    }
}
