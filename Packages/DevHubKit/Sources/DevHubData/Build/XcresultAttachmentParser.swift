import Foundation
import DevHubDomain

enum XcresultAttachmentParser {
    private struct Entry: Decodable {
        struct Attachment: Decodable {
            let exportedFileName: String?
            let suggestedHumanReadableName: String?
            let isAssociatedWithFailure: Bool?
        }

        let testIdentifier: String?
        let attachments: [Attachment]?
    }

    static func attachments(from data: Data, folder: URL) throws -> [TestAttachment] {
        guard let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            throw TestRunError.failed("xcresulttool wrote an unexpected attachment list.")
        }
        return entries.flatMap { entry -> [TestAttachment] in
            guard let test = entry.testIdentifier else { return [] }
            return (entry.attachments ?? []).compactMap { attachment in
                guard let file = attachment.exportedFileName, file.isEmpty == false else { return nil }
                return TestAttachment(
                    testIdentifier: test,
                    name: displayName(attachment.suggestedHumanReadableName ?? file),
                    path: folder.appendingPathComponent(file).path,
                    isAssociatedWithFailure: attachment.isAssociatedWithFailure ?? false
                )
            }
        }
    }

    static func displayName(_ suggested: String) -> String {
        let base = (suggested as NSString).deletingPathExtension
        let parts = base.split(separator: "_", omittingEmptySubsequences: false)
        guard parts.count >= 3, let last = parts.last, UUID(uuidString: String(last)) != nil, Int(parts[parts.count - 2]) != nil else { return base }
        return parts.dropLast(2).joined(separator: "_")
    }
}
