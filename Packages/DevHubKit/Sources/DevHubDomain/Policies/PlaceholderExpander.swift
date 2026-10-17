import Foundation

package enum PlaceholderExpander {
    private static let urlSafe = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~/"))

    package static func expand(_ text: String, values: [String: String], encodesForURL: Bool) -> String {
        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            guard character == "{", let close = text[index...].firstIndex(of: "}") else {
                result.append(character)
                index = text.index(after: index)
                continue
            }
            let name = String(text[text.index(after: index)..<close])
            if let value = values[name] {
                result += encodesForURL ? (value.addingPercentEncoding(withAllowedCharacters: urlSafe) ?? value) : value
                index = text.index(after: close)
            } else {
                result.append(character)
                index = text.index(after: index)
            }
        }
        return result
    }
}
