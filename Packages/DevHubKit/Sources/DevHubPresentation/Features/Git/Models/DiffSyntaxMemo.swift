import Foundation
import DevHubDomain

@MainActor
final class DiffSyntaxMemo: Equatable {
    private struct Key: Hashable {
        let lines: [String]
        let language: SyntaxLanguage
    }

    private var tokens: [Key: [[SyntaxToken]]] = [:]
    private var order: [Key] = []

    static let limit = 64

    nonisolated static func == (lhs: DiffSyntaxMemo, rhs: DiffSyntaxMemo) -> Bool {
        lhs === rhs
    }

    var count: Int {
        tokens.count
    }

    func tokens(forHunkLines lines: [String], language: SyntaxLanguage) -> [[SyntaxToken]] {
        let key = Key(lines: lines, language: language)
        if let known = tokens[key] {
            return known
        }
        let computed = DiffSyntaxPolicy.tokens(forHunkLines: lines, language: language)
        tokens[key] = computed
        order.append(key)
        if order.count > Self.limit {
            tokens[order.removeFirst()] = nil
        }
        return computed
    }
}
