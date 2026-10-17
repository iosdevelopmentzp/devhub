import Foundation
import DevHubDomain

enum TicketMapper {

    static func model(for texts: [String], template: String) -> TicketModel? {
        guard let key = texts.lazy.compactMap(TicketPrefix.key(in:)).first else { return nil }
        let url = TicketPrefix.url(forKey: key, template: template)
        return TicketModel(
            key: key,
            url: url,
            hint: url == nil ? "Copy \(key). Set the ticket link in Settings to open it." : "Open \(key) in the tracker"
        )
    }
}
