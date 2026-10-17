import Foundation

enum GitLabLayout: Equatable {
    case inline
    case split(listWidth: CGFloat)

    static let wideWidth: CGFloat = 960
    static let defaultListFraction: CGFloat = 0.42
    static let minListWidth: CGFloat = 320
    static let minDetailsWidth: CGFloat = 440

    static func layout(forWidth width: CGFloat, listFraction: CGFloat) -> GitLabLayout {
        guard width >= wideWidth else { return .inline }
        return .split(listWidth: listWidth(forFraction: listFraction, in: width))
    }

    static func listWidth(forFraction fraction: CGFloat, in width: CGFloat) -> CGFloat {
        min(max((width * fraction).rounded(), minListWidth), width - minDetailsWidth)
    }

    static func fraction(forListWidth listWidth: CGFloat, in width: CGFloat) -> CGFloat {
        guard width > 0 else { return defaultListFraction }
        return self.listWidth(forFraction: listWidth / width, in: width) / width
    }

    var isSplit: Bool {
        self != .inline
    }
}
