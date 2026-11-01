import Foundation
import DevHubDomain

enum GhUserListParser {
    private struct User: Decodable {
        let login: String?
    }

    static func logins(from data: Data) throws -> [String] {
        do {
            let users = try JSONDecoder().decode([User].self, from: data)
            return users.compactMap(\.login).filter { $0.isEmpty == false }.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        } catch {
            throw PullRequestError.command("gh returned an unexpected list of people.")
        }
    }
}
