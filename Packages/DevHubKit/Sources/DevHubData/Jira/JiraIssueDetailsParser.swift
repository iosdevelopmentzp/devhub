import Foundation
import DevHubDomain

enum JiraIssueDetailsParser {
    static func details(from data: Data) throws -> TrackerIssueDetails {
        let dto: DetailsDTO
        do {
            dto = try JSONDecoder().decode(DetailsDTO.self, from: data)
        } catch {
            throw TrackerError.unreadable(error.localizedDescription)
        }
        let fields = dto.fields
        return TrackerIssueDetails(
            key: dto.key,
            description: fields.description.map(text(of:)) ?? "",
            reporter: fields.reporter?.displayName,
            createdAt: fields.created.flatMap(JiraDateParser.date(from:)),
            labels: fields.labels ?? [],
            components: (fields.components ?? []).compactMap(\.name),
            parent: fields.parent.map(link(from:)),
            subtasks: (fields.subtasks ?? []).map(link(from:)),
            comments: (fields.comment?.comments ?? []).enumerated().map { index, comment in
                TrackerComment(
                    id: comment.id ?? "\(index)",
                    author: comment.author?.displayName ?? "",
                    body: comment.body.map(text(of:)) ?? "",
                    createdAt: comment.created.flatMap(JiraDateParser.date(from:))
                )
            },
            fixVersions: (fields.fixVersions ?? []).compactMap(\.name),
            dueDate: fields.duedate.flatMap { JiraDateParser.day(from: $0, calendar: .current) },
            resolution: fields.resolution?.name,
            links: (fields.issuelinks ?? []).compactMap(relation(from:)),
            attachments: (fields.attachment ?? []).compactMap(\.filename),
            originalEstimateSeconds: fields.timetracking?.originalEstimateSeconds,
            timeSpentSeconds: fields.timetracking?.timeSpentSeconds,
            remainingEstimateSeconds: fields.timetracking?.remainingEstimateSeconds,
            watchers: fields.watches?.watchCount,
            isWatching: fields.watches?.isWatching
        )
    }

    private static func relation(from dto: DetailsDTO.IssueLink) -> TrackerIssueRelation? {
        if let inward = dto.inwardIssue {
            return TrackerIssueRelation(relation: dto.type?.inward ?? dto.type?.name ?? "", issue: link(from: inward))
        }
        if let outward = dto.outwardIssue {
            return TrackerIssueRelation(relation: dto.type?.outward ?? dto.type?.name ?? "", issue: link(from: outward))
        }
        return nil
    }

    private static func link(from dto: LinkDTO) -> TrackerIssueLink {
        TrackerIssueLink(
            key: dto.key,
            summary: dto.fields?.summary ?? "",
            status: dto.fields?.status?.name ?? "",
            statusCategory: JiraIssueParser.category(forKey: dto.fields?.status?.statusCategory?.key)
        )
    }

    private static func text(of value: TextDTO) -> String {
        switch value {
        case .plain(let text):
            return text.replacingOccurrences(of: "\r\n", with: "\n").trimmed
        case .document(let node):
            let raw = text(of: node)
            return raw.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression).trimmed
        }
    }

    private static func text(of node: NodeDTO) -> String {
        let children = (node.content ?? []).map(text(of:)).joined()
        switch node.type {
        case "text":
            return node.text ?? ""
        case "hardBreak":
            return "\n"
        case "mention", "emoji", "status", "date":
            return node.attrs?.text ?? node.attrs?.shortName ?? ""
        case "inlineCard", "blockCard":
            return node.attrs?.url ?? ""
        case "listItem":
            return "• " + children.trimmed + "\n"
        case "paragraph", "heading", "codeBlock", "blockquote", "panel", "rule":
            return children + "\n\n"
        case "bulletList", "orderedList":
            return children + "\n"
        default:
            return children
        }
    }
}

private struct DetailsDTO: Decodable {
    let key: String
    let fields: Fields

    struct Fields: Decodable {
        let description: TextDTO?
        let reporter: Person?
        let created: String?
        let labels: [String]?
        let components: [Named]?
        let parent: LinkDTO?
        let subtasks: [LinkDTO]?
        let comment: CommentPage?
        let fixVersions: [Named]?
        let duedate: String?
        let resolution: Named?
        let issuelinks: [IssueLink]?
        let attachment: [Attachment]?
        let timetracking: TimeTracking?
        let watches: Watches?
    }

    struct IssueLink: Decodable {
        let type: LinkType?
        let inwardIssue: LinkDTO?
        let outwardIssue: LinkDTO?
    }

    struct LinkType: Decodable {
        let name: String?
        let inward: String?
        let outward: String?
    }

    struct Attachment: Decodable {
        let filename: String?
    }

    struct TimeTracking: Decodable {
        let originalEstimateSeconds: Int?
        let remainingEstimateSeconds: Int?
        let timeSpentSeconds: Int?
    }

    struct Watches: Decodable {
        let watchCount: Int?
        let isWatching: Bool?
    }

    struct Person: Decodable {
        let displayName: String?
    }

    struct Named: Decodable {
        let name: String?
    }

    struct CommentPage: Decodable {
        let comments: [Comment]?
    }

    struct Comment: Decodable {
        let id: String?
        let author: Person?
        let body: TextDTO?
        let created: String?
    }
}

private struct LinkDTO: Decodable {
    let key: String
    let fields: Fields?

    struct Fields: Decodable {
        let summary: String?
        let status: Status?
    }

    struct Status: Decodable {
        let name: String?
        let statusCategory: Category?
    }

    struct Category: Decodable {
        let key: String?
    }
}

private enum TextDTO: Decodable {
    case plain(String)
    case document(NodeDTO)

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .plain(text)
        } else {
            self = .document(try container.decode(NodeDTO.self))
        }
    }
}

private struct NodeDTO: Decodable {
    let type: String?
    let text: String?
    let content: [NodeDTO]?
    let attrs: Attributes?

    struct Attributes: Decodable {
        let text: String?
        let shortName: String?
        let url: String?

        enum CodingKeys: String, CodingKey {
            case text
            case shortName
            case url
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            text = try? container.decodeIfPresent(String.self, forKey: .text)
            shortName = try? container.decodeIfPresent(String.self, forKey: .shortName)
            url = try? container.decodeIfPresent(String.self, forKey: .url)
        }
    }
}
