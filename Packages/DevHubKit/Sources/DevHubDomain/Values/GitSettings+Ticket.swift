import Foundation

extension GitSettings {
    package func ticket(fallbackURL: String) -> TicketSettings {
        TicketSettings(pattern: ticketPattern, format: ticketFormat, urlTemplate: ticketURL ?? fallbackURL)
    }
}
