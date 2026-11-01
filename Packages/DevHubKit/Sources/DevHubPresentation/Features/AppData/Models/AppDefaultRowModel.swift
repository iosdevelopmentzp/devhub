import Foundation
import DevHubDomain
import DevHubUI

struct AppDefaultRowModel: Identifiable, Equatable {
    let id: String
    var key: String
    var kind: AppDefault.Kind
    var kindTag: TagModel
    var valueText: String
    var editText: String
    var canEdit: Bool
    var toggleValue: AppDefaultValue?
    var toggleHint: String?
    var readOnlyHint: String?

    static let preview = AppDefaultRowModel(
        id: "apiEnvironment",
        key: "apiEnvironment",
        kind: .string,
        kindTag: TagModel("string", tint: .secondary),
        valueText: "staging",
        editText: "staging",
        canEdit: true,
        toggleValue: nil,
        toggleHint: nil,
        readOnlyHint: nil
    )
}
