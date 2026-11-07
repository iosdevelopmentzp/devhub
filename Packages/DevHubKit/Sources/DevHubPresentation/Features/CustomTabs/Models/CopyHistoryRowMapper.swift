import Foundation
import DevHubDomain
import DevHubUI

enum CopyHistoryRowMapper {
    static func model(for record: ConfigCopyRecord) -> CopyHistoryRowModel {
        CopyHistoryRowModel(
            id: record.id,
            text: record.text,
            detail: "\(record.title) · \(record.date.relativeDescription)",
            resendHint: record.open == nil ? "Copy again" : "Copy again and open \(record.open ?? "")"
        )
    }
}
