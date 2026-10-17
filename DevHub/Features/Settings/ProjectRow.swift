import SwiftUI

struct ProjectRow: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigStore.self) private var config
    @Environment(SettingsTabStore.self) private var store

    let project: Project

    @State private var isHovered = false
    @State private var isConfirmingRemove = false

    private var isCurrent: Bool { session.project == project }

    private var effective: EffectiveProject {
        config.effective(for: project, isCurrent: isCurrent)
    }

    private var detection: ProjectDetection? { session.detections[project.path] }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                IconTile(systemImage: "cube", tint: isCurrent ? .indigo : .gray, size: 32)
                info
                    .frame(maxWidth: .infinity, alignment: .leading)
                controls
            }
            if isConfirmingRemove {
                InlineConfirm(
                    text: "Remove \(project.name) from DevHub? The folder and its files stay on disk.",
                    confirmTitle: "Remove",
                    tint: .red,
                    onCancel: { isConfirmingRemove = false },
                    onConfirm: { session.remove(project) }
                )
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.snappy(duration: 0.18), value: isConfirmingRemove)
        .contextMenu { menuItems }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(effective.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                if isCurrent {
                    Tag("current", tint: .blue)
                }
            }
            Text(project.path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .copyOnClick(project.path, label: "path")
            FlowLayout(spacing: 6, lineSpacing: 4) {
                Tag(detection?.kindTitle ?? "Detecting…", tint: .gray)
                if let scheme = effective.scheme {
                    Tag("scheme \(scheme)", tint: .teal)
                }
                if let bundleID = effective.bundleID {
                    Text(bundleID)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .copyOnClick(bundleID, label: "bundle ID")
                }
                if detection?.isGitRepository == false {
                    Tag("no git", tint: .orange)
                }
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 2) {
            if isCurrent == false {
                Button("Switch") { session.select(project) }
                    .controlSize(.small)
                    .fixedSize()
            }
            HStack(spacing: 2) {
                IconButton(systemImage: "arrow.clockwise", help: "Detect the container, schemes and bundle ID again") { store.redetect(project) }
                IconButton(systemImage: "folder", help: "Open the .devhub folder") { store.revealConfigFolder(of: project) }
                IconButton(systemImage: "trash", help: "Remove from DevHub", tint: .red) { isConfirmingRemove = true }
            }
            .opacity(isHovered || isConfirmingRemove ? 1 : 0)
        }
    }

    @ViewBuilder
    private var menuItems: some View {
        Button("Switch to this project", systemImage: "arrow.right.circle") { session.select(project) }
            .disabled(isCurrent)
        Button("Detect again", systemImage: "arrow.clockwise") { store.redetect(project) }
        Button("Open .devhub folder", systemImage: "folder") { store.revealConfigFolder(of: project) }
        Button("Create .devhub example", systemImage: "doc.badge.plus") { store.createExample(for: project) }
        Divider()
        Button("Remove", systemImage: "trash") { isConfirmingRemove = true }
    }
}

#Preview {
    ProjectRow(project: Project(path: NSHomeDirectory()))
        .padding()
        .previewEnvironment()
}
