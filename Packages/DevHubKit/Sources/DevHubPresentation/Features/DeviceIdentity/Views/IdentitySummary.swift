import SwiftUI
import DevHubDomain
import DevHubUI

struct IdentitySummary: View {
    let model: IdentitySummaryModel

    var body: some View {
        FlowLayout(spacing: 6, lineSpacing: 3) {
            if model.isApplying {
                HStack(spacing: 5) {
                    ProgressView()
                        .controlSize(.mini)
                    Text(model.applyingText)
                }
            } else {
                ModelTag(model: model.environmentTag)
                if let deviceID = model.deviceID {
                    HStack(spacing: 4) {
                        if let alias = model.deviceAlias {
                            Text(alias)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        Text(deviceID)
                            .font(.caption2.monospaced())
                            .lineLimit(1)
                    }
                    .copyOnClick(deviceID, label: deviceID)
                }
                if let userText = model.userText, let copyValue = model.userCopyValue {
                    HStack(spacing: 3) {
                        Image(systemName: model.userIcon)
                        Text(userText)
                            .lineLimit(1)
                    }
                    .copyOnClick(copyValue, label: model.userCopyLabel ?? copyValue)
                } else if let notLoggedInText = model.notLoggedInText {
                    Text(notLoggedInText)
                }
                if let nextDeviceTag = model.nextDeviceTag {
                    ModelTag(model: nextDeviceTag)
                }
                if let mockTag = model.mockTag {
                    ModelTag(model: mockTag)
                }
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    IdentitySummary(model: .preview)
        .padding()
}
