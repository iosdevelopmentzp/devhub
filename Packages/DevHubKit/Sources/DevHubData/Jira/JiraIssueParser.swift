import Foundation
import DevHubDomain

enum JiraIssueParser {
    static func issues(from data: Data) throws -> [TrackerIssue] {
        let decoder = JSONDecoder()
        if let search = try? decoder.decode(SearchDTO.self, from: data) {
            return search.issues.map(issue(from:))
        }
        if let list = try? decoder.decode([IssueDTO].self, from: data) {
            return list.map(issue(from:))
        }
        do {
            return [issue(from: try decoder.decode(IssueDTO.self, from: data))]
        } catch {
            throw TrackerError.unreadable(error.localizedDescription)
        }
    }

    static func issue(from data: Data) throws -> TrackerIssue {
        do {
            return issue(from: try JSONDecoder().decode(IssueDTO.self, from: data))
        } catch {
            throw TrackerError.unreadable(error.localizedDescription)
        }
    }

    static func browseURL(apiURL: String?, key: String) -> URL? {
        guard let apiURL, let range = apiURL.range(of: "/rest/") else { return nil }
        return URL(string: apiURL[..<range.lowerBound] + "/browse/" + key)
    }

    static func category(forKey key: String?) -> IssueStatusCategory {
        switch key {
        case "new": .toDo
        case "indeterminate": .inProgress
        case "done": .done
        default: .unknown
        }
    }

    private static func issue(from dto: IssueDTO) -> TrackerIssue {
        TrackerIssue(
            key: dto.key,
            summary: dto.fields.summary ?? "",
            status: dto.fields.status?.name ?? "",
            statusCategory: category(forKey: dto.fields.status?.statusCategory?.key),
            type: dto.fields.issuetype?.name ?? "",
            priority: dto.fields.priority?.name,
            assignee: dto.fields.assignee?.displayName,
            url: browseURL(apiURL: dto.apiURL, key: dto.key),
            updatedAt: dto.fields.updated.flatMap(JiraDateParser.date(from:))
        )
    }
}

private struct SearchDTO: Decodable {
    let issues: [IssueDTO]
}

private struct IssueDTO: Decodable {
    let key: String
    let apiURL: String?
    let fields: Fields

    enum CodingKeys: String, CodingKey {
        case key
        case apiURL = "self"
        case fields
    }

    struct Fields: Decodable {
        let summary: String?
        let status: Status?
        let issuetype: Named?
        let priority: Named?
        let assignee: Person?
        let updated: String?
    }

    struct Status: Decodable {
        let name: String?
        let statusCategory: Category?
    }

    struct Category: Decodable {
        let key: String?
    }

    struct Named: Decodable {
        let name: String?
    }

    struct Person: Decodable {
        let displayName: String?
    }
}
