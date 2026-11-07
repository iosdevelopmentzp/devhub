import AppKit
import SwiftUI

package struct FileImage: View {
    package let path: String
    package let maxHeight: CGFloat

    @State private var image: NSImage?
    @State private var isMissing = false

    package init(path: String, maxHeight: CGFloat = 160) {
        self.path = path
        self.maxHeight = maxHeight
    }

    package var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: maxHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Theme.border)
                    )
            } else if isMissing {
                Label("Image not found", systemImage: "photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .controlSize(.mini)
            }
        }
        .task(id: path) {
            image = NSImage(contentsOfFile: path)
            isMissing = image == nil
        }
    }
}

#Preview {
    FileImage(path: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns")
        .padding()
}
