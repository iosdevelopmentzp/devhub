import Foundation
import DevHubDomain

struct MockNetworkSourceRepository: NetworkSourceRepository {
    func follow(_ request: ScriptRunRequest) -> AsyncThrowingStream<NetworkSourceEvent, any Error> {
        AsyncThrowingStream { continuation in
            for request in MockData.sourceScriptExchanges {
                continuation.yield(.request(request))
            }
        }
    }
}
