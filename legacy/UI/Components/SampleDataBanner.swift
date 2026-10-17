import SwiftUI

struct SampleDataBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
            Text("Sample data. This screen is not connected to real data yet.")
                .lineLimit(1)
                .hintWhenTruncated("Sample data. This screen is not connected to real data yet.")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tint.yellow.color.opacity(0.12))
    }
}

#Preview {
    SampleDataBanner()
        .previewEnvironment()
}
