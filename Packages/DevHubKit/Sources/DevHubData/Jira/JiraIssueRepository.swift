import Foundation
import DevHubDomain

struct JiraIssueRepository: IssueTrackerRepository {
    let client: JiraClient
    let tools: any ToolLocating
    let configFile: String

    init(shell: ShellRunner, tools: any ToolLocating, configFile: String) {
        client = JiraClient(shell: shell)
        self.tools = tools
        self.configFile = configFile
    }

    func toolState() async -> TrackerToolState {
        guard tools.path(of: "jira") != nil else { return .missing }
        guard tools.fileExists(atPath: configFile) else { return .notConfigured }
        let version = (try? await client.output(JiraClient.versionArguments())).flatMap { DoctorPolicy.version(from: [$0.stdout]) }
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

    func issues(jql: String, project: String?, limit: Int) async throws -> [TrackerIssue] {
        let data = try await client.run(JiraClient.issueListArguments(jql: jql, project: project, limit: limit))
        return try JiraIssueParser.issues(from: data)
    }

    func issue(key: String) async throws -> TrackerIssue {
        let data = try await client.run(JiraClient.issueViewArguments(key: key))
        return try JiraIssueParser.issue(from: data)
    }

    func transition(key: String, to status: String) async throws {
        _ = try await client.run(JiraClient.moveArguments(key: key, status: status))
    }
}
