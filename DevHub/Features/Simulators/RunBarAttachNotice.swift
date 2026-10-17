import SwiftUI

struct RunBarAttachNotice: View {
    @Environment(BuildStore.self) private var build

    let notice: AttachNotice

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "ladybug")
                .foregroundStyle(Tint.orange.color)
            VStack(alignment: .leading, spacing: 3) {
                Text(notice.message)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                if let steps = notice.steps {
                    Text(steps)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if notice.canRequestAccess {
                Button("Request access") { build.requestAccessibility() }
                    .controlSize(.small)
                    .fixedSize()
            }
        }
        .padding(8)
        .background(Tint.orange.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    RunBarAttachNotice(notice: AttachNotice(message: AttachAdvice.accessMessage, steps: AttachAdvice.manualSteps(processID: 123), canRequestAccess: true))
        .padding()
        .previewEnvironment()
}
