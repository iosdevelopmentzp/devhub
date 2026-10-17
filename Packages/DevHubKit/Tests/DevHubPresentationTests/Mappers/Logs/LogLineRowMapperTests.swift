import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct LogLineRowMapperTests {
    @Test func everyLevel() {
        let table: [(AppLogLine.Level, String, Tint, Double, Tint?)] = [
            (.debug, "Debug", .secondary, 0.5, nil),
            (.info, "Info", .blue, 1, nil),
            (.notice, "Default", .gray, 1, nil),
            (.error, "Error", .red, 1, .red),
            (.fault, "Fault", .purple, 1, .purple)
        ]
        #expect(table.map(\.0) == AppLogLine.Level.allCases)

        for (level, title, tint, opacity, messageTint) in table {
            let model = LogLineRowMapper.model(for: AppLogLine(id: 1, date: nil, level: level, category: "Net", message: "m"))
            #expect(LogLineRowMapper.title(for: level) == title)
            #expect(model.levelTitle == title)
            #expect(model.levelTint == tint)
            #expect(model.levelOpacity == opacity)
            #expect(model.messageTint == messageTint)
        }
    }

    @Test func fieldsAndTimestamp() {
        let date = Date(timeIntervalSince1970: 1_000)

        let model = LogLineRowMapper.model(for: AppLogLine(id: 7, date: date, level: .info, category: "Networking", message: "Request sent"))

        #expect(model.id == 7)
        #expect(model.timestamp == LogTimestamp.text(date))
        #expect(model.timestamp.isEmpty == false)
        #expect(model.category == "Networking")
        #expect(model.message == "Request sent")
    }

    @Test func missingDateAndCategory() {
        let model = LogLineRowMapper.model(for: AppLogLine(id: 1, date: nil, level: .info, category: "", message: "m"))

        #expect(model.timestamp == "")
        #expect(model.category == nil)
    }
}
