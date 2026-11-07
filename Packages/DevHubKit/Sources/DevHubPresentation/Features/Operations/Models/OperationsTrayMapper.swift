import Foundation
import DevHubDomain
import DevHubUI

enum OperationsTrayMapper {
    static func cards(for records: [OperationRecord], entries: [CommandLog.Entry], origin: OperationOrigin?) -> [OperationCardModel] {
        records
            .filter { $0.isDismissed == false && (origin == nil || $0.origin == origin) }
            .map { OperationCardMapper.model(for: $0, entries: entries) }
    }
}
