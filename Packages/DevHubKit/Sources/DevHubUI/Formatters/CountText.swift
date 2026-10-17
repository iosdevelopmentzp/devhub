import Foundation

package enum CountText {

    package static func count(_ n: Int, _ singular: String, _ plural: String? = nil) -> String {
        "\(n) \(n == 1 ? singular : plural ?? singular + "s")"
    }

    package static func invariant(_ n: Int, _ noun: String) -> String {
        "\(n) \(noun)"
    }
}
