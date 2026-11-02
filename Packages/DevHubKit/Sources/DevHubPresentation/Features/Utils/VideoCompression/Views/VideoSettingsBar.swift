import SwiftUI
import DevHubDomain
import DevHubUI

struct VideoSettingsBar: View {
    @Binding var settings: VideoCompressionSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text("Quality")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Picker("Quality", selection: $settings.quality) {
                    ForEach(VideoQuality.allCases, id: \.self) { quality in
                        Text(VideoCompressionText.title(for: quality))
                            .tag(quality)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                Spacer(minLength: 8)
                Toggle("Keep sound", isOn: $settings.keepsAudio)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                    .fixedSize()
                    .hint("Off: the result has no audio track")
            }
            Text(VideoCompressionText.description(for: settings.quality))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VideoSettingsBar(settings: .constant(.standard))
        .padding()
}
