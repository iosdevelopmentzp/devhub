import Foundation
import DevHubDomain

enum GhAuthStatusParser {
    private struct StatusDTO: Decodable {
        let hosts: [String: [AccountDTO]]?
    }

    private struct AccountDTO: Decodable {
        let state: String?
        let active: Bool?
        let login: String?
        let scopes: String?
    }

    static func access(from data: Data, host: String) throws -> CodeHostAccess {
        guard let status = try? JSONDecoder().decode(StatusDTO.self, from: data) else {
            throw PullRequestError.command("gh returned an unexpected login status.")
        }
        let accounts = status.hosts?[host] ?? []
        guard let account = accounts.first(where: { $0.active == true }) ?? accounts.first, account.state == "success" else {
            throw PullRequestError.notLoggedIn(tool: "gh", host: host)
        }
        return CodeHostAccess(login: account.login, scopes: scopes(account.scopes))
    }

    private static func scopes(_ text: String?) -> [String]? {
        let scopes = (text ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.isEmpty == false }
        return scopes.isEmpty ? nil : scopes
    }
}
