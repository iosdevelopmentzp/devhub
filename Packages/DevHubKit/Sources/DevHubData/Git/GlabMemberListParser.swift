import Foundation
import DevHubDomain

enum GlabMemberListParser {
    private struct Member: Decodable {
        let username: String?
        let state: String?
    }

    static func usernames(from data: Data) throws -> [String] {
        let pages = JSONPages.split(data)
        guard pages.isEmpty == false else { throw unexpected }
        let decoder = JSONDecoder()
        var members: [Member] = []
        for page in pages {
            if let list = try? decoder.decode([Member].self, from: page) {
                members += list
            } else if let member = try? decoder.decode(Member.self, from: page) {
                members.append(member)
            } else {
                throw unexpected
            }
        }
        let active = members.filter { $0.state == nil || $0.state == "active" }.compactMap(\.username).filter { $0.isEmpty == false }
        return Array(Set(active)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private static var unexpected: PullRequestError {
        .command("glab returned an unexpected list of members.")
    }
}
