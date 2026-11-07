import Testing
@testable import DevHubDomain

@Suite struct TrackerSettingsPolicyTests {
    @Test func anEmptyConfigHasNoTrackerAndTheDefaults() {
        let settings = TrackerSettingsPolicy.settings(for: ProjectConfig())

        #expect(settings.kind == .disabled)
        #expect(settings.project == nil)
        #expect(settings.statuses == ["To Do", "In Progress", "In Review", "Done"])
        #expect(settings.startStatus == "In Progress")
        #expect(settings.filter == nil)
        #expect(settings.branchFormat == "feature/{key}-{slug}")
    }

    @Test func theTrackerSectionWins() {
        let config = ProjectConfig(tracker: TrackerConfig(kind: .jira, project: " ABC ", statuses: ["Open", " ", "Closed"], startStatus: "Open", filter: "type != Epic", branchFormat: "fix/{key}"))

        let settings = TrackerSettingsPolicy.settings(for: config)

        #expect(settings.kind == .jira)
        #expect(settings.project == "ABC")
        #expect(settings.statuses == ["Open", "Closed"])
        #expect(settings.startStatus == "Open")
        #expect(settings.filter == "type != Epic")
        #expect(settings.branchFormat == "fix/{key}")
    }

    @Test func aJiraTicketLinkTurnsTheTrackerOn() {
        let selfHosted = ProjectConfig(git: GitConfig(ticketURL: "https://jira.example.com/browse/{key}"))
        let other = ProjectConfig(git: GitConfig(ticketURL: "https://tickets.example.com/{key}"))
        let explicit = ProjectConfig(git: GitConfig(ticketURL: "https://jira.example.com/browse/{key}"), tracker: TrackerConfig(kind: .disabled))

        #expect(TrackerSettingsPolicy.settings(for: selfHosted).kind == .jira)
        #expect(TrackerSettingsPolicy.settings(for: other).kind == .disabled)
        #expect(TrackerSettingsPolicy.settings(for: explicit).kind == .disabled)
    }

    @Test func anAtlassianHostCountsAsJira() {
        #expect(TrackerSettingsPolicy.detectKind(ticketURL: "example.atlassian.net/browse/{key}") == .jira)
        #expect(TrackerSettingsPolicy.detectKind(ticketURL: "Example.ATLASSIAN.com/{key}") == .jira)
        #expect(TrackerSettingsPolicy.detectKind(ticketURL: nil) == .disabled)
        #expect(TrackerSettingsPolicy.detectKind(ticketURL: "") == .disabled)
    }
}
