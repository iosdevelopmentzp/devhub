import Foundation

enum JSONPages {
    private static let openers: Set<UInt8> = [UInt8(ascii: "["), UInt8(ascii: "{")]
    private static let closers: Set<UInt8> = [UInt8(ascii: "]"), UInt8(ascii: "}")]
    private static let quote = UInt8(ascii: "\"")
    private static let backslash = UInt8(ascii: "\\")

    static func split(_ data: Data) -> [Data] {
        var pages: [Data] = []
        var depth = 0
        var start: Int?
        var isInString = false
        var isEscaped = false
        let bytes = [UInt8](data)
        for (index, byte) in bytes.enumerated() {
            if isInString {
                if isEscaped {
                    isEscaped = false
                } else if byte == backslash {
                    isEscaped = true
                } else if byte == quote {
                    isInString = false
                }
                continue
            }
            if byte == quote {
                isInString = true
            } else if openers.contains(byte) {
                if depth == 0 {
                    start = index
                }
                depth += 1
            } else if closers.contains(byte), depth > 0 {
                depth -= 1
                if depth == 0, let begin = start {
                    pages.append(Data(bytes[begin...index]))
                    start = nil
                }
            }
        }
        return pages
    }
}
