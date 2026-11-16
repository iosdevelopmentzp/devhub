import Foundation
import DevHubDomain

enum GlabAccessParser {
    private struct UserDTO: Decodable {
        let username: String?
    }

    private struct TokenDTO: Decodable {
        let scopes: [String]?
    }

    static func login(from data: Data) throws -> String? {
        guard let user = try? JSONDecoder().decode(UserDTO.self, from: data) else {
            throw PullRequestError.command("glab returned an unexpected user.")
        }
        return user.username
    }

    static func scopes(from data: Data) throws -> [String]? {
        guard let token = try? JSONDecoder().decode(TokenDTO.self, from: data) else {
            throw PullRequestError.command("glab returned an unexpected token.")
        }
        return token.scopes
    }
}
