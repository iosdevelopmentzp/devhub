import Foundation
import DevHubDomain

struct DeviceChrome: Equatable, Sendable {
    struct Insets: Equatable, Sendable {
        var top: Double
        var left: Double
        var bottom: Double
        var right: Double

        static let zero = Insets(top: 0, left: 0, bottom: 0, right: 0)
    }

    struct Pieces: Equatable, Sendable {
        var topLeft: String
        var top: String
        var topRight: String
        var right: String
        var bottomRight: String
        var bottom: String
        var bottomLeft: String
        var left: String
    }

    struct Button: Equatable, Sendable {
        var image: String
        var anchor: String
        var align: String
        var onTop: Bool
        var x: Double
        var y: Double
    }

    var pieces: Pieces
    var composite: String?
    var sizing: Insets
    var padding: Insets
    var buttons: [Button]
}
