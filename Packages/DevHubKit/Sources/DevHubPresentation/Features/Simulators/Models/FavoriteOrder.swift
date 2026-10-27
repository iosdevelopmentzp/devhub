import Foundation
import DevHubDomain
import DevHubUI

enum FavoriteOrder {

    static func moved(_ order: [String], id: String, onto target: String) -> [String] {
        guard id != target, let from = order.firstIndex(of: id), let to = order.firstIndex(of: target) else { return order }
        var result = order
        result.remove(at: from)
        result.insert(id, at: to)
        return result
    }

    static func rank(of id: String, in order: [String]) -> Int {
        order.firstIndex(of: id) ?? order.count
    }
}
