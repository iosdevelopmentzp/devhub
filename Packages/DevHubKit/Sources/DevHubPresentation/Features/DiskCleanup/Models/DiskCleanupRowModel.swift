import Foundation
import DevHubDomain

struct DiskCleanupRowModel: Identifiable, Equatable {
    let id: DiskCleanupItem.ID
    var icon: String
    var title: String
    var detail: String
    var sizeText: String?
    var isMeasuring: Bool
    var isBusy: Bool
    var canDelete: Bool
    var deleteHint: String
    var confirmTitle: String
    var warnings: [String]

    static let preview = DiskCleanupRowModel(
        id: "archives",
        icon: "archivebox",
        title: "Archives",
        detail: "6 folders in ~/Library/Developer/Xcode/Archives",
        sizeText: "4.6 GB",
        isMeasuring: false,
        isBusy: false,
        canDelete: true,
        deleteHint: "rm -rf 6 folders",
        confirmTitle: "Delete Archives (4.6 GB)?",
        warnings: ["Archives keep the dSYM files of shipped builds."]
    )
}
