import Testing
import DevHubDomain
@testable import DevHubPresentation

@Suite struct ConfigIssueRowMapperTests {
    @Test func namesTheLayerAndTheFile() {
        let model = ConfigIssueRowMapper.model(for: ConfigIssue(layer: .user, fileName: "actions/a.json", message: "id: this key is required."))

        #expect(model.location == "user: actions/a.json")
        #expect(model.message == "id: this key is required.")
        #expect(ConfigIssueRowMapper.title(count: 1) == "1 config problem")
        #expect(ConfigIssueRowMapper.title(count: 3) == "3 config problems")
    }
}
