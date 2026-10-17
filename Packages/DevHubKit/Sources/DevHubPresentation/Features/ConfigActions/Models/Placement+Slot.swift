import Foundation
import DevHubDomain

extension Placement {
    var slot: String {
        rawValue
    }

    func slot(for rowID: String) -> String {
        "\(rawValue):\(rowID)"
    }
}
