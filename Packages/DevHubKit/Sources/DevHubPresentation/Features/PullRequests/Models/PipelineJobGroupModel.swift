import Foundation
import DevHubUI

struct PipelineJobGroupModel: Identifiable, Equatable {
    let id: String
    var title: String?
    var icon: String
    var tint: Tint
    var statusText: String
    var jobs: [PipelineJobRowModel]

    static let preview = PipelineJobGroupModel(
        id: "test",
        title: "test",
        icon: "xmark.circle.fill",
        tint: .red,
        statusText: "1 failed · 1 running",
        jobs: [.preview]
    )
}
