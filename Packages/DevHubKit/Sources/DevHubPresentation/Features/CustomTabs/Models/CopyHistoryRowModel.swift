import Foundation
import DevHubDomain
import DevHubUI

struct CopyHistoryRowModel: Identifiable, Equatable {
    let id: ConfigCopyRecord.ID
    var text: String
    var detail: String
    var resendHint: String

    static let preview = CopyHistoryRowModel(id: UUID(), text: "/qabot coins 1234 10000", detail: "Top up coins · 5 min. ago", resendHint: "Copy again and open the channel")
}
