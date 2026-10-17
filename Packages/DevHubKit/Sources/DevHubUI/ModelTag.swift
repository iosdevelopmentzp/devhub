import SwiftUI

package struct ModelTag: View {
    package let model: TagModel
    package let isPlain: Bool

    package init(model: TagModel, isPlain: Bool = false) {
        self.model = model
        self.isPlain = isPlain
    }

    package var body: some View {
        Group {
            if isPlain {
                PlainTag(model.text, tint: model.tint.color, systemImage: model.systemImage)
            } else {
                Tag(model.text, tint: model.tint.color, systemImage: model.systemImage)
            }
        }
        .hint(model.hint)
    }
}

#Preview {
    HStack {
        ModelTag(model: TagModel("clean", tint: .green, systemImage: "checkmark"))
        ModelTag(model: TagModel("3 changed", tint: .orange, systemImage: "pencil", hint: "Uncommitted changes"))
        ModelTag(model: TagModel("locked", systemImage: "lock.fill"))
        ModelTag(model: .icon("checkmark.circle.fill", tint: .green, hint: "Pipeline passed"))
        ModelTag(model: TagModel("approved", systemImage: "checkmark.seal"), isPlain: true)
    }
    .padding()
}
