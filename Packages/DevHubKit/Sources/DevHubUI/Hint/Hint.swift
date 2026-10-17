import Foundation

package struct Hint: Equatable {
    package let id: UUID
    package let text: String
    package let frame: CGRect

    package init(id: UUID, text: String, frame: CGRect) {
        self.id = id
        self.text = text
        self.frame = frame
    }
}
