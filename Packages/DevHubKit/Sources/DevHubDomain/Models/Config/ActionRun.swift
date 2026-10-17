import Foundation

package enum ActionRun: Hashable, Sendable, Codable {
    case script(String)
    case command([String])
    case terminal(String)
    case open(String)

    private enum CodingKeys: String, CodingKey {
        case script, command, terminal, open
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(String.self, forKey: .script) {
            self = .script(value)
        } else if let value = try container.decodeIfPresent([String].self, forKey: .command) {
            self = .command(value)
        } else if let value = try container.decodeIfPresent(String.self, forKey: .terminal) {
            self = .terminal(value)
        } else if let value = try container.decodeIfPresent(String.self, forKey: .open) {
            self = .open(value)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "run needs one of script, command, terminal or open.")
            )
        }
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .script(value): try container.encode(value, forKey: .script)
        case let .command(value): try container.encode(value, forKey: .command)
        case let .terminal(value): try container.encode(value, forKey: .terminal)
        case let .open(value): try container.encode(value, forKey: .open)
        }
    }
}
