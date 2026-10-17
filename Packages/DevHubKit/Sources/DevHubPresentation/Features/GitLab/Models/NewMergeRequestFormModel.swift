import Foundation

struct NewMergeRequestFormModel: Equatable {
    var heading: String
    var createTitle: String
    var createHint: String
    var canCreate: Bool
    var isBusy: Bool
    var busyText: String?

    static let preview = NewMergeRequestFormModel(
        heading: "New merge request from feature/ABC-2324-paid-call",
        createTitle: "Push & Create",
        createHint: "Push the branch with git push -u origin feature/ABC-2324-paid-call, then create the merge request",
        canCreate: true,
        isBusy: false,
        busyText: nil
    )
}
