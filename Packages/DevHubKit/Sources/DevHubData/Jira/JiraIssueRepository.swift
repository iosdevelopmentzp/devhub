import Foundation
import DevHubDomain

struct JiraIssueRepository: IssueTrackerRepository {
    let client: JiraClient
    let tools: any ToolLocating
    let configFile: String

    init(client: JiraClient, tools: any ToolLocating, configFile: String) {
        self.client = client
        self.tools = tools
        self.configFile = configFile
    }

    func toolState() async -> TrackerToolState {
        guard tools.path(of: "jira") != nil else { return .missing }
        guard tools.fileExists(atPath: configFile) else { return .notConfigured }
        let version = (try? await client.launch(JiraClient.versionArguments(), environment: [:])).flatMap { DoctorPolicy.version(from: [$0.stdout]) }
        do {
            let me = try await client.run(JiraClient.meArguments())
            let user = JiraClient.plainText(String(decoding: me, as: UTF8.self))
            return .ready(version: version, user: user.isEmpty ? nil : user)
        } catch TrackerError.notLoggedIn {
            return .notLoggedIn
        } catch TrackerError.notConfigured {
            return .notConfigured
        } catch TrackerError.notInstalled {
            return .missing
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func issues(jql: String, project: String?, order: IssueOrder, limit: Int) async throws -> [TrackerIssue] {
        let data = try await client.run(JiraClient.issueListArguments(jql: jql, project: project, order: order, limit: limit))
        return try JiraIssueParser.issues(from: data)
    }

    func issue(key: String) async throws -> TrackerIssue {
        let data = try await client.run(JiraClient.issueViewArguments(key: key))
        return try JiraIssueParser.issue(from: data)
    }

    func details(key: String) async throws -> TrackerIssueDetails {
        let data = try await client.run(JiraClient.issueViewArguments(key: key))
        return try JiraIssueDetailsParser.details(from: data)
    }

    func transition(key: String, to status: String) async throws {
        _ = try await client.run(JiraClient.moveArguments(key: key, status: status))
    }

    func assign(key: String, to user: String) async throws {
        _ = try await client.run(JiraClient.assignArguments(key: key, user: user))
    }

    func comment(key: String, text: String) async throws {
        _ = try await client.run(JiraClient.commentArguments(key: key, text: text))
    }
}
