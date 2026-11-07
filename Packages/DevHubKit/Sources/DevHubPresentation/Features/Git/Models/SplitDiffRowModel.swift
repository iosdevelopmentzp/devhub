import Foundation
import DevHubUI

struct SplitDiffRowModel: Identifiable, Equatable {
    let id: Int
    var header: DiffLineModel?
    var old: DiffLineModel?
    var new: DiffLineModel?

    var lineIDs: [Int] {
        [header?.id, old?.id, new?.id].compactMap { $0 }
    }

    static let preview = SplitDiffRowModel(
        id: 1,
        header: nil,
        old: DiffLineModel(id: 1, text: "-    let value: Int", tint: .red, foregroundOpacity: 0.9, backgroundOpacity: 0.08, oldNumber: 42, newNumber: nil, emphasis: [16..<19]),
        new: .preview
    )
}
