import Foundation

enum SwiftKeywords {
    static let words: [String] = [
        "actor", "any", "as", "associatedtype", "async", "await", "borrowing", "break", "case", "catch", "class", "consuming",
        "continue", "convenience", "default", "defer", "deinit", "didSet", "do", "dynamic", "each", "else", "enum", "extension",
        "fallthrough", "false", "fileprivate", "final", "for", "func", "get", "guard", "if", "import", "in", "indirect", "infix",
        "init", "inout", "internal", "is", "isolated", "lazy", "let", "macro", "mutating", "nil", "nonisolated", "nonmutating",
        "open", "operator", "optional", "override", "package", "postfix", "precedencegroup", "prefix", "private", "protocol",
        "public", "repeat", "required", "rethrows", "return", "self", "Self", "set", "some", "static", "struct", "subscript",
        "super", "switch", "throw", "throws", "true", "try", "typealias", "unowned", "var", "weak", "where", "while", "willSet",
    ]

    static let byLength: [Int: [[Unicode.Scalar]]] = Dictionary(grouping: words.map { Array($0.unicodeScalars) }, by: \.count)

    static func contains(_ scalars: ArraySlice<Unicode.Scalar>) -> Bool {
        guard let candidates = byLength[scalars.count] else { return false }
        return candidates.contains { $0.elementsEqual(scalars) }
    }
}
