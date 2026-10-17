import Foundation
import DevHubDomain
import DevHubUI

enum DiffModel: Equatable {
    case loading
    case note(String)
    case lines([DiffLineModel], droppedNote: String?)

    static let preview = DiffModel.lines(
        [
            DiffLineModel(id: 0, text: "@@ -12,7 +12,8 @@ struct CallPromptView: View {", tint: .blue, foregroundOpacity: 1, backgroundOpacity: 0.06),
            DiffLineModel(id: 1, text: "-    let value: Int", tint: .red, foregroundOpacity: 0.9, backgroundOpacity: 0.08),
            .preview
        ],
        droppedNote: nil
    )
}
