import Foundation
import DevHubUI

struct PullRequestFileSidebarModel: Equatable {
    var title: String
    var progressText: String
    var progress: Double
    var groups: [PullRequestFileGroupChipModel]
    var rows: [PullRequestFileSidebarRowModel]
    var emptyText: String?

    static let preview = PullRequestFileSidebarModel(
        title: "Files 2",
        progressText: "1 of 2 viewed",
        progress: 0.5,
        groups: [.preview],
        rows: [
            .preview,
            PullRequestFileSidebarRowModel(id: "ExampleUI/Calls/PaymentSheet.swift", letter: "A", letterTint: .green, fileName: "PaymentSheet.swift", folder: "ExampleUI/Calls", path: "ExampleUI/Calls/PaymentSheet.swift", additionsText: "+2", deletionsText: "−0", isViewed: true, isExpanded: false, isChanged: false, threadCountText: nil, hint: "ExampleUI/Calls/PaymentSheet.swift. Click to show its diff."),
        ],
        emptyText: nil
    )
}
