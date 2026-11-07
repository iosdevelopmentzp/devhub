import SwiftUI
import DevHubDomain
import DevHubUI

struct UtilityContent: View {
    let id: UtilityID

    var body: some View {
        switch id {
        case .compressVideo:
            VideoCompressionView()
        }
    }
}

#Preview {
    UtilityContent(id: .compressVideo)
        .previewEnvironment()
}
