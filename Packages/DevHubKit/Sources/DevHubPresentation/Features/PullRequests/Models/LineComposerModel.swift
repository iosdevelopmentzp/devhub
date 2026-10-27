import Foundation

struct LineComposerModel: Equatable {
    var lineID: Int
    var text: String
    var placeholder: String
    var isBusy: Bool
    var canSend: Bool

    static let preview = LineComposerModel(lineID: 1, text: "", placeholder: "Comment on line 42…", isBusy: false, canSend: false)
}
