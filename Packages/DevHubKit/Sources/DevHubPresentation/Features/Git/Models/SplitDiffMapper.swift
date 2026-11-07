import Foundation

enum SplitDiffMapper {

    static func rows(from lines: [DiffLineModel]) -> [SplitDiffRowModel] {
        var rows: [SplitDiffRowModel] = []
        var removed: [DiffLineModel] = []
        var added: [DiffLineModel] = []
        func flush() {
            for index in 0..<max(removed.count, added.count) {
                let old = index < removed.count ? removed[index] : nil
                let new = index < added.count ? added[index] : nil
                rows.append(SplitDiffRowModel(id: (old ?? new)!.id, header: nil, old: old, new: new))
            }
            removed = []
            added = []
        }
        for line in lines {
            if line.text.hasPrefix("-") {
                if added.isEmpty == false {
                    flush()
                }
                removed.append(line)
            } else if line.text.hasPrefix("+") {
                added.append(line)
            } else if line.text.hasPrefix("\\") {
                continue
            } else {
                flush()
                if line.text.hasPrefix("@@") {
                    rows.append(SplitDiffRowModel(id: line.id, header: line, old: nil, new: nil))
                } else {
                    rows.append(SplitDiffRowModel(id: line.id, header: nil, old: line, new: line))
                }
            }
        }
        flush()
        return rows
    }
}
