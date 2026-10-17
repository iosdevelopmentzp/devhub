import SwiftUI
import DevHubDomain
import DevHubUI

struct ProjectCard: View {
    @Environment(Toaster.self) private var toaster
    @Environment(AppActions.self) private var appActions

    let model: ProjectCardModel

    var body: some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    IconTile(systemImage: "shippingbox.fill", tint: .indigo, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.name)
                            .font(.title3.weight(.semibold))
                        HStack(spacing: 4) {
                            Text(model.path)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .copyOnClick(model.path, label: model.path)
                            Button {
                                toaster.copy(model.path)
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .hint("Copy path")
                        }
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 6) {
                    ModelTag(model: model.branchTag)
                        .copyOnClick(model.branchTag.text, label: model.branchTag.text)
                    ForEach(model.statusTags, id: \.self) { tag in
                        ModelTag(model: tag)
                    }
                }

                HStack(spacing: 6) {
                    Button("Finder", systemImage: "folder") {
                        appActions.openInFinder(path: model.mainCheckoutPath)
                    }
                    Button("Xcode", systemImage: "hammer") {
                        appActions.openInXcode(path: model.mainCheckoutPath)
                    }
                    Button("Terminal", systemImage: "terminal") {
                        appActions.openTerminal(at: model.path)
                    }
                    Button("GitLab", systemImage: "link") {
                        appActions.openRepository()
                    }
                    Spacer()
                }
                .controlSize(.small)
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    ProjectCard(model: .preview)
        .previewEnvironment()
}
