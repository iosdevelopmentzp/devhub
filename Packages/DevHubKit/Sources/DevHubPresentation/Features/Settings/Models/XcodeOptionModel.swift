import Foundation

struct XcodeOptionModel: Identifiable, Hashable {
    let id: String
    let title: String

    static let preview = XcodeOptionModel(id: "/Applications/Xcode-beta.app/Contents/Developer", title: "Xcode 26.2 · Xcode-beta.app")
}
