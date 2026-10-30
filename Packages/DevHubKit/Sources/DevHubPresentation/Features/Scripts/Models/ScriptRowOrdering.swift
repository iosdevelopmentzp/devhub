import Foundation

struct ScriptRowOrdering {
    let onToggleFavorite: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
}
