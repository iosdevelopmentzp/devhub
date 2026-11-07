import Foundation

struct TestAttachmentRowModel: Identifiable, Equatable {
    let id: String
    var name: String
    var path: String
    var isImage: Bool
    var hint: String

    static let preview = TestAttachmentRowModel(
        id: "/tmp/DevHub-tests/Attachments/ExampleApp/answer.txt",
        name: "Server answer",
        path: "/tmp/DevHub-tests/Attachments/ExampleApp/answer.txt",
        isImage: false,
        hint: "Open Server answer"
    )
}
