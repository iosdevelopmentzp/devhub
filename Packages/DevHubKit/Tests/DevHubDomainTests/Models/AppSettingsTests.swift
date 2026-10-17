import Foundation
import Testing
@testable import DevHubDomain

@Suite struct AppSettingsTests {
    @Test func oldSettingsWithoutNewKeysKeepTheirValues() throws {
        let old = Data(#"{"showDockIcon":true,"showUsageStrip":false,"showUsageInMenuBar":false,"globalShortcut":"optionCommandD","scriptsFolder":"~/s","editor":"Cursor","terminal":"iTerm"}"#.utf8)

        let settings = try JSONDecoder().decode(AppSettings.self, from: old)

        #expect(settings.showDockIcon)
        #expect(settings.showUsageStrip == false)
        #expect(settings.showUsageInMenuBar == false)
        #expect(settings.showReviewCountInMenuBar)
        #expect(settings.scriptsFolder == "~/s")
        #expect(settings.editor == "Cursor")
        #expect(settings.terminal == "iTerm")
        #expect(settings.ticketURLTemplate == "")
        #expect(settings.autoFetchMinutes == 0)
    }

    @Test func theTicketTemplateIsKept() throws {
        let data = Data(#"{"ticketURLTemplate":"https://jira.example.com/browse/{key}"}"#.utf8)

        let settings = try JSONDecoder().decode(AppSettings.self, from: data)

        #expect(settings.ticketURLTemplate == "https://jira.example.com/browse/{key}")
        #expect(settings.editor == "Xcode")
    }

    @Test func settingsRoundTrip() throws {
        let settings = AppSettings(showDockIcon: true, showReviewCountInMenuBar: false, editor: "Cursor", autoFetchMinutes: 15)

        let decoded = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))

        #expect(decoded == settings)
    }
}
