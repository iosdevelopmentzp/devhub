import Foundation
import DevHubDomain
import DevHubUI

struct ProjectCardModel: Equatable {
    var name: String
    var path: String
    var mainCheckoutPath: String
    var branchTag: TagModel
    var statusTags: [TagModel]

    static let preview = ProjectCardModel(
        name: "ExampleApp",
        path: "/Users/dev/Projects/ExampleApp",
        mainCheckoutPath: "/Users/dev/Projects/ExampleApp",
        branchTag: TagModel("develop", tint: .blue, systemImage: "arrow.triangle.branch"),
        statusTags: [
            TagModel("3 changed", tint: .orange, systemImage: "pencil"),
            TagModel("↑2"),
            TagModel("↓1", tint: .red)
        ]
    )
}
