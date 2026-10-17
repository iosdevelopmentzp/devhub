import SwiftUI

struct RunBarTarget: View {
    @Environment(BuildStore.self) private var build
    @Environment(SimulatorsStore.self) private var store

    var body: some View {
        HStack(spacing: 8) {
            Text("Target")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let target = build.target {
                Image(systemName: target.symbol)
                    .foregroundStyle(Tint.blue.color)
                Text(target.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                Tag(target.runtime, tint: .gray)
                Text(target.isBooted ? "Booted" : "Shutdown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let status = store.statuses[target.id] {
                    Text(status.text)
                        .font(.caption)
                        .foregroundStyle(status.isFailure ? Tint.red.color : Tint.indigo.color)
                        .lineLimit(1)
                        .hintWhenTruncated(status.text)
                }
            } else {
                Text("No simulator. Pick one in the list below.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    RunBarTarget()
        .padding()
        .previewEnvironment()
}
