import Foundation

package enum DiffLineEmphasis {
    package struct Pair: Hashable, Sendable {
        package let removed: Int
        package let added: Int

        package init(removed: Int, added: Int) {
            self.removed = removed
            self.added = added
        }
    }

    package struct Ranges: Hashable, Sendable {
        package let removed: [Range<Int>]
        package let added: [Range<Int>]

        package init(removed: [Range<Int>], added: [Range<Int>]) {
            self.removed = removed
            self.added = added
        }
    }

    package static let tokenLimit = 300
    package static let minimumSimilarity = 0.4

    package static func pairs(in lines: [String]) -> [Pair] {
        var pairs: [Pair] = []
        var removed: [Int] = []
        var added: [Int] = []
        func flush() {
            pairs += zip(removed, added).map { Pair(removed: $0, added: $1) }
            removed = []
            added = []
        }
        for (index, line) in lines.enumerated() {
            if line.hasPrefix("-") {
                if added.isEmpty == false {
                    flush()
                }
                removed.append(index)
            } else if line.hasPrefix("+") {
                added.append(index)
            } else if line.hasPrefix("\\") == false {
                flush()
            }
        }
        flush()
        return pairs
    }

    package static func ranges(removed: String, added: String) -> Ranges? {
        let removedTokens = tokens(removed)
        let addedTokens = tokens(added)
        guard removedTokens.count <= tokenLimit, addedTokens.count <= tokenLimit else { return nil }
        let matched = commonTokens(removedTokens, addedTokens)
        let commonLength = matched.reduce(0) { $0 + removedTokens[$1.0].count }
        guard Double(commonLength) * 2 >= Double(removed.count + added.count) * minimumSimilarity else { return nil }
        return Ranges(
            removed: changedRanges(removedTokens, matchedIndices: Set(matched.map(\.0))),
            added: changedRanges(addedTokens, matchedIndices: Set(matched.map(\.1)))
        )
    }

    private static func tokens(_ text: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var currentKind: Character.Kind?
        for character in text {
            let kind = character.kind
            if kind == currentKind, kind != .other {
                current.append(character)
                continue
            }
            if current.isEmpty == false {
                tokens.append(current)
            }
            current = String(character)
            currentKind = kind
        }
        if current.isEmpty == false {
            tokens.append(current)
        }
        return tokens
    }

    private static func commonTokens(_ left: [String], _ right: [String]) -> [(Int, Int)] {
        guard left.isEmpty == false, right.isEmpty == false else { return [] }
        var table = [[Int]](repeating: [Int](repeating: 0, count: right.count + 1), count: left.count + 1)
        for i in stride(from: left.count - 1, through: 0, by: -1) {
            for j in stride(from: right.count - 1, through: 0, by: -1) {
                table[i][j] = left[i] == right[j] ? table[i + 1][j + 1] + 1 : max(table[i + 1][j], table[i][j + 1])
            }
        }
        var matched: [(Int, Int)] = []
        var i = 0
        var j = 0
        while i < left.count, j < right.count {
            if left[i] == right[j] {
                matched.append((i, j))
                i += 1
                j += 1
            } else if table[i + 1][j] >= table[i][j + 1] {
                i += 1
            } else {
                j += 1
            }
        }
        return matched
    }

    private static func changedRanges(_ tokens: [String], matchedIndices: Set<Int>) -> [Range<Int>] {
        var ranges: [Range<Int>] = []
        var offset = 0
        for (index, token) in tokens.enumerated() {
            defer { offset += token.count }
            guard matchedIndices.contains(index) == false else { continue }
            if let last = ranges.last, last.upperBound == offset {
                ranges[ranges.count - 1] = last.lowerBound..<(offset + token.count)
            } else {
                ranges.append(offset..<(offset + token.count))
            }
        }
        return ranges
    }
}

private extension Character {
    enum Kind {
        case word
        case space
        case other
    }

    var kind: Kind {
        if isLetter || isNumber || self == "_" {
            return .word
        }
        if isWhitespace {
            return .space
        }
        return .other
    }
}
