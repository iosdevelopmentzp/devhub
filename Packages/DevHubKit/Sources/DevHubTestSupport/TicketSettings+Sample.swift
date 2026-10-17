import DevHubDomain

extension TicketSettings {
    package static func linking(_ template: String) -> TicketSettings {
        var ticket = TicketSettings.standard
        ticket.urlTemplate = template
        return ticket
    }
}
