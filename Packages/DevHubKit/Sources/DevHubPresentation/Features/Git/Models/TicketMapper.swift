import Foundation
import DevHubDomain

enum TicketMapper {

    static func model(for texts: [String], ticket: TicketSettings) -> TicketModel? {
        guard let key = texts.lazy.compactMap({ TicketPrefix.key(in: $0, ticket: ticket) }).first else { return nil }
        let url = TicketPrefix.url(forKey: key, template: ticket.urlTemplate)
        return TicketModel(
            key: key,
            url: url,
            hint: url == nil ? "Copy \(key). Set git.ticketURL in .devhub/project.json or the ticket link in Settings to open it." : "Open \(key) in the tracker"
        )
    }
}
