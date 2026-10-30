import Foundation

struct SchemeEditorModel: Equatable {
    var manual: [String]
    var suggestions: [String]
    var message: String?
    var isLoading: Bool

    static let preview = SchemeEditorModel(
        manual: ["ExampleWidget"],
        suggestions: ["ExampleApp Staging", "NotificationServiceExtension"],
        message: nil,
        isLoading: false
    )
}
