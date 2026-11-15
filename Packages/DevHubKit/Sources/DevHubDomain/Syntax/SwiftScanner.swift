import Foundation

struct SwiftScanner {
    let scalars: [Unicode.Scalar]
    var state: SyntaxState
    var tokens: [SyntaxToken] = []
    private var position = 0

    init(scalars: [Unicode.Scalar], state: SyntaxState) {
        self.scalars = scalars
        self.state = state
    }

    mutating func run() {
        switch state {
        case .code:
            scanCode(inInterpolation: false)
        case .blockComment(let depth):
            scanBlockComment(from: position, depth: depth)
            scanCode(inInterpolation: false)
        case .multilineString(let hashes):
            scanMultilineString(from: position, hashes: hashes)
            scanCode(inInterpolation: false)
        }
    }

    private var count: Int {
        scalars.count
    }

    private func scalar(at index: Int) -> Unicode.Scalar? {
        index < count ? scalars[index] : nil
    }

    private func matches(_ first: Unicode.Scalar, _ second: Unicode.Scalar, at index: Int) -> Bool {
        scalar(at: index) == first && scalar(at: index + 1) == second
    }

    private func matchesTripleQuote(at index: Int) -> Bool {
        matches("\"", "\"", at: index) && scalar(at: index + 2) == "\""
    }

    private func isDigit(_ scalar: Unicode.Scalar) -> Bool {
        ("0"..."9").contains(scalar)
    }

    private func hashes(at index: Int) -> Int {
        var length = 0
        while scalar(at: index + length) == "#" {
            length += 1
        }
        return length
    }

    private mutating func emit(_ kind: SyntaxTokenKind, from start: Int, to end: Int) {
        guard end > start else { return }
        tokens.append(SyntaxToken(range: start..<end, kind: kind))
    }

    private mutating func scanCode(inInterpolation: Bool) {
        var parenDepth = 0
        while position < count {
            let current = scalars[position]
            if inInterpolation {
                if current == "(" {
                    parenDepth += 1
                } else if current == ")" {
                    guard parenDepth > 0 else { return }
                    parenDepth -= 1
                }
            }
            if current == "/", scalar(at: position + 1) == "/" {
                emit(.comment, from: position, to: count)
                position = count
                return
            }
            if current == "/", scalar(at: position + 1) == "*" {
                let start = position
                position += 2
                scanBlockComment(from: start, depth: 1)
                guard state == .code else { return }
                continue
            }
            if current == "\"" {
                scanStringStart(hashes: 0)
                guard state == .code else { return }
                continue
            }
            if current == "#" {
                let length = hashes(at: position)
                if scalar(at: position + length) == "\"" {
                    scanStringStart(hashes: length)
                    guard state == .code else { return }
                    continue
                }
                if length == 1, let next = scalar(at: position + 1), next.properties.isAlphabetic {
                    let start = position
                    position += 1
                    skipIdentifier()
                    emit(.directive, from: start, to: position)
                    continue
                }
                position += length
                continue
            }
            if current == "@" {
                let start = position
                position += 1
                skipIdentifier()
                if position > start + 1 {
                    emit(.attribute, from: start, to: position)
                }
                continue
            }
            if current == "`" {
                position += 1
                while let next = scalar(at: position), next != "`" {
                    position += 1
                }
                position += 1
                continue
            }
            if isDigit(current) {
                scanNumber()
                continue
            }
            if isIdentifierStart(current) {
                let start = position
                skipIdentifier()
                let word = scalars[start..<position]
                if SwiftKeywords.contains(word) {
                    emit(.keyword, from: start, to: position)
                } else if current.properties.isUppercase {
                    emit(.type, from: start, to: position)
                }
                continue
            }
            position += 1
        }
    }

    private func isIdentifierStart(_ scalar: Unicode.Scalar) -> Bool {
        scalar == "_" || scalar == "$" || scalar.properties.isAlphabetic
    }

    private func isIdentifierPart(_ scalar: Unicode.Scalar) -> Bool {
        isIdentifierStart(scalar) || isDigit(scalar)
    }

    private mutating func skipIdentifier() {
        while let next = scalar(at: position), isIdentifierPart(next) {
            position += 1
        }
    }

    private mutating func scanNumber() {
        let start = position
        var digits = CharacterSet.decimalDigits
        if scalars[position] == "0", let prefix = scalar(at: position + 1) {
            switch prefix {
            case "x", "X":
                digits = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
                position += 2
            case "b", "B":
                digits = CharacterSet(charactersIn: "01")
                position += 2
            case "o", "O":
                digits = CharacterSet(charactersIn: "01234567")
                position += 2
            default:
                break
            }
        }
        skipDigits(digits)
        if scalar(at: position) == ".", let next = scalar(at: position + 1), digits.contains(next) {
            position += 1
            skipDigits(digits)
        }
        if let exponent = scalar(at: position), exponent == "e" || exponent == "E" || exponent == "p" || exponent == "P" {
            var ahead = position + 1
            if let sign = scalar(at: ahead), sign == "+" || sign == "-" {
                ahead += 1
            }
            if let next = scalar(at: ahead), CharacterSet.decimalDigits.contains(next) {
                position = ahead
                skipDigits(.decimalDigits)
            }
        }
        emit(.number, from: start, to: position)
    }

    private mutating func skipDigits(_ digits: CharacterSet) {
        while let next = scalar(at: position), digits.contains(next) || next == "_" {
            position += 1
        }
    }

    private mutating func scanBlockComment(from start: Int, depth: Int) {
        var depth = depth
        while position < count {
            if matches("/", "*", at: position) {
                depth += 1
                position += 2
            } else if matches("*", "/", at: position) {
                depth -= 1
                position += 2
                if depth == 0 {
                    break
                }
            } else {
                position += 1
            }
        }
        emit(.comment, from: start, to: position)
        state = depth == 0 ? .code : .blockComment(depth: depth)
    }

    private mutating func scanStringStart(hashes: Int) {
        let start = position
        position += hashes
        if matchesTripleQuote(at: position) {
            position += 3
            state = .multilineString(hashes: hashes)
            scanMultilineString(from: start, hashes: hashes)
        } else {
            position += 1
            scanString(from: start, hashes: hashes)
        }
    }

    private mutating func scanString(from start: Int, hashes: Int) {
        var start = start
        while position < count {
            let current = scalars[position]
            if current == "\\", hashes == 0 || matchesHashes(hashes, at: position + 1) {
                let after = position + 1 + hashes
                if scalar(at: after) == "(" {
                    position = after + 1
                    emit(.string, from: start, to: position)
                    scanCode(inInterpolation: true)
                    start = position
                    if scalar(at: position) == ")" {
                        position += 1
                    }
                    continue
                }
                position = after + 1
                continue
            }
            if current == "\"", matchesHashes(hashes, at: position + 1) {
                position += 1 + hashes
                emit(.string, from: start, to: position)
                return
            }
            position += 1
        }
        emit(.string, from: start, to: position)
    }

    private mutating func scanMultilineString(from start: Int, hashes: Int) {
        var start = start
        while position < count {
            let current = scalars[position]
            if current == "\\", hashes == 0 || matchesHashes(hashes, at: position + 1) {
                let after = position + 1 + hashes
                if scalar(at: after) == "(" {
                    position = after + 1
                    emit(.string, from: start, to: position)
                    scanCode(inInterpolation: true)
                    start = position
                    if scalar(at: position) == ")" {
                        position += 1
                    }
                    continue
                }
                position = after + 1
                continue
            }
            if matchesTripleQuote(at: position), matchesHashes(hashes, at: position + 3) {
                position += 3 + hashes
                emit(.string, from: start, to: position)
                state = .code
                return
            }
            position += 1
        }
        emit(.string, from: start, to: position)
        state = .multilineString(hashes: hashes)
    }

    private func matchesHashes(_ hashes: Int, at index: Int) -> Bool {
        guard hashes > 0 else { return true }
        return self.hashes(at: index) >= hashes
    }
}
