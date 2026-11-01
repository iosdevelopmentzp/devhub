import Foundation
import DevHubDomain

enum GlabMemberListParser {
    private struct Member: Decodable {
        let username: String?
        let state: String?
    }

    static func usernames(from data: Data) throws -> [String] {
        do {
            let members = try JSONDecoder().decode([Member].self, from: data)
            let active = members.filter { $0.state == nil || $0.state == "active" }.compactMap(\.username).filter { $0.isEmpty == false }
            return Array(Set(active)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        } catch {
            throw PullRequestError.command("glab returned an unexpected list of members.")
        }
    }
}
