import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct CopyHistoryRowMapperTests {
    @Test func textTitleAndTheOpenTargetInTheHint() {
        let record = ConfigCopyRecord(projectPath: "/repo", tabID: "chat", actionID: "coins", title: "Top up coins", text: "/qabot coins 12 100", open: "example://chat", date: Date())

        let model = CopyHistoryRowMapper.model(for: record)

        #expect(model.id == record.id)
        #expect(model.text == "/qabot coins 12 100")
        #expect(model.detail.hasPrefix("Top up coins · "))
        #expect(model.resendHint == "Copy again and open example://chat")
    }

    @Test func aRecordWithoutAnOpenTargetOnlyCopies() {
        let record = ConfigCopyRecord(projectPath: "/repo", tabID: nil, actionID: "coins", title: "Top up coins", text: "x", open: nil, date: Date())

        #expect(CopyHistoryRowMapper.model(for: record).resendHint == "Copy again")
    }
}
