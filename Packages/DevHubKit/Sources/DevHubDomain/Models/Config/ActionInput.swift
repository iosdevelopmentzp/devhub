import Foundation

package struct ActionInput: Codable, Hashable, Sendable, Identifiable {
    package var key: String
    package var title: String
    package var type: InputType
    package var options: [InputOption]? = nil
    package var defaultValue: String? = nil
    package var remember: Bool? = nil
    package var placeholder: String? = nil

    package var id: String {
        key
    }

    package init(
        key: String,
        title: String,
        type: InputType,
        options: [InputOption]? = nil,
        defaultValue: String? = nil,
        remember: Bool? = nil,
        placeholder: String? = nil
    ) {
        self.key = key
        self.title = title
        self.type = type
        self.options = options
        self.defaultValue = defaultValue
        self.remember = remember
        self.placeholder = placeholder
    }

    private enum CodingKeys: String, CodingKey {
        case key, title, type, options, remember, placeholder
        case defaultValue = "default"
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? key
        type = try container.decode(InputType.self, forKey: .type)
        options = try container.decodeIfPresent([InputOption].self, forKey: .options)
        defaultValue = try container.decodeFlexibleString(forKey: .defaultValue)
        remember = try container.decodeIfPresent(Bool.self, forKey: .remember)
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
    }
}
