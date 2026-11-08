import Foundation
import DevHubDomain

enum WebSocketMessage: Equatable {
    case text(String)
    case binary(Int)
    case close(UInt16?)
    case ping
    case pong
}
