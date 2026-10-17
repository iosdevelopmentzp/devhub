import SwiftUI
import DevHubDomain
import DevHubUI

struct TicketChip: View {
    @Environment(Toaster.self) private var toaster
    @Environment(AppActions.self) private var appActions

    let model: TicketModel

    var body: some View {
        Button {
            guard let url = model.url else {
                toaster.copy(model.key, label: model.key)
                return
            }
            appActions.open(url)
        } label: {
            Tag(model.key, tint: Tint.indigo.color, systemImage: "ticket")
        }
        .buttonStyle(.plain)
        .hint(model.hint)
    }
}

#Preview {
    TicketChip(model: .preview)
        .padding()
        .previewEnvironment()
}
