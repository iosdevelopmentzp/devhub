import Foundation
import DevHubDomain

enum GhUserListParser {
    private struct User: Decodable {
        let login: String?
    }

    static func logins(from data: Data) throws -> [String] {
        let users = try pages(data)
        let logins = users.compactMap(\.login).filter { $0.isEmpty == false }
        return Array(Set(logins)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private static func pages(_ data: Data) throws -> [User] {
        let decoder = JSONDecoder()
        if let pages = try? decoder.decode([[User]].self, from: data) {
            return pages.flatMap { $0 }
        }
        guard let users = try? decoder.decode([User].self, from: data) else {
            throw PullRequestError.command("gh returned an unexpected list of people.")
        }
        return users
    }
}
