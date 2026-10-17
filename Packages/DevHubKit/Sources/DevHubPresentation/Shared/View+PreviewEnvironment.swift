import SwiftUI
import DevHubDomain
import DevHubUI

extension View {

    func previewEnvironment() -> some View {
        inject(PresentationAssembly.preview())
            .frame(width: 720, height: 820)
    }
}
