import Foundation

package enum CatalogAction: Identifiable, Hashable, Sendable {
    case builtin(BuiltinAction)
    case config(ResolvedAction)

    package var id: String {
        switch self {
        case let .builtin(builtin): builtin.id
        case let .config(resolved): resolved.id
        }
    }

    package var resolved: ResolvedAction? {
        guard case let .config(resolved) = self else { return nil }
        return resolved
    }

    package var origin: ActionOrigin? {
        resolved?.origin
    }

    package var inputs: [ActionInput] {
        resolved?.config.inputs ?? []
    }

    package var confirm: String? {
        resolved?.config.confirm
    }

    package var needsPrompt: Bool {
        inputs.isEmpty == false || confirm != nil
    }

    package var isRunnable: Bool {
        origin?.isExecutable ?? true
    }

    package var fileName: String? {
        origin.map { URL(fileURLWithPath: $0.fileName).lastPathComponent }
    }
}
