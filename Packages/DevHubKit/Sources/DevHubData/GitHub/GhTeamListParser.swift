import Foundation
import DevHubDomain

enum GhTeamListParser {
    private struct Organization: Decodable {
        let login: String?
    }

    private struct Team: Decodable {
        let slug: String?
        let organization: Organization?
    }

    static func myTeams(from data: Data, owner: String) throws -> [String] {
        let teams = try pages(data).compactMap { team -> String? in
            guard let slug = team.slug, slug.isEmpty == false,
                  let organization = team.organization?.login,
                  organization.caseInsensitiveCompare(owner) == .orderedSame
            else { return nil }
            return "\(organization)/\(slug)"
        }
        return sorted(teams)
    }

    static func repositoryTeams(from data: Data, owner: String) throws -> [String] {
        let teams = try pages(data).compactMap { team -> String? in
            guard let slug = team.slug, slug.isEmpty == false else { return nil }
            return "\(owner)/\(slug)"
        }
        return sorted(teams)
    }

    private static func pages(_ data: Data) throws -> [Team] {
        let decoder = JSONDecoder()
        if let pages = try? decoder.decode([[Team]].self, from: data) {
            return pages.flatMap { $0 }
        }
        guard let teams = try? decoder.decode([Team].self, from: data) else {
            throw PullRequestError.command("gh returned an unexpected list of teams.")
        }
        return teams
    }

    private static func sorted(_ teams: [String]) -> [String] {
        Array(Set(teams)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}
