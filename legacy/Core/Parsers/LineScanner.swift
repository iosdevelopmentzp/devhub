import Foundation

nonisolated enum LineScanner {
    static func forEachLine(in data: Data, _ body: (UnsafeRawBufferPointer) -> Bool) {
        data.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress else { return }
            var start = 0
            while start < buffer.count {
                let remaining = buffer.count - start
                let newline = memchr(base + start, 10, remaining)
                let end = newline.map { base.distance(to: UnsafeRawPointer($0)) } ?? buffer.count
                let line = UnsafeRawBufferPointer(start: base + start, count: end - start)
                if body(line) == false { return }
                start = end + 1
            }
        }
    }

    static func forEachLineReversed(in data: Data, _ body: (UnsafeRawBufferPointer) -> Bool) {
        data.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress else { return }
            var end = buffer.count
            while end > 0 {
                var start = end
                while start > 0, buffer[start - 1] != 10 {
                    start -= 1
                }
                let line = UnsafeRawBufferPointer(start: base + start, count: end - start)
                if body(line) == false { return }
                end = start - 1
            }
        }
    }

    static func hasPrefix(_ line: UnsafeRawBufferPointer, _ prefix: StaticString) -> Bool {
        guard line.count >= prefix.utf8CodeUnitCount, let base = line.baseAddress else { return false }
        return memcmp(base, prefix.utf8Start, prefix.utf8CodeUnitCount) == 0
    }

    static func contains(_ line: UnsafeRawBufferPointer, _ needle: StaticString) -> Bool {
        guard let base = line.baseAddress, line.count >= needle.utf8CodeUnitCount else { return false }
        return memmem(base, line.count, needle.utf8Start, needle.utf8CodeUnitCount) != nil
    }

    static func object(_ line: UnsafeRawBufferPointer) -> [String: Any]? {
        guard let base = line.baseAddress else { return nil }
        let data = Data(bytes: base, count: line.count)
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
