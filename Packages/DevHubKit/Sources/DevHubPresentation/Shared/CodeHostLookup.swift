import Foundation
import DevHubDomain

@MainActor
protocol CodeHostLookup: AnyObject {
    var remoteName: String { get }
    var kind: CodeHostKind? { get }
    func codeHost() async throws -> CodeHost
}

extension CodeHostLookup {
    var words: CodeHostWords {
        CodeHostWords(kind: kind)
    }
}
