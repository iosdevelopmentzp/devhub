import Foundation

package extension String {

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
