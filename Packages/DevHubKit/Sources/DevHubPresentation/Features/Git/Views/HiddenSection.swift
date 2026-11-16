import SwiftUI
import DevHubDomain
import DevHubUI

struct HiddenSection: View {
    @Environment(GitHiddenFilesStore.self) private var hidden
    @Environment(GitStore.self) private var git
    @Environment(SettingsStore.self) private var settings
    @Environment(ProjectSession.self) private var session

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("git does not show the changes of these files (git update-index). Click a file to see its hidden changes.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Menu("Hide a File…", systemImage: "eye.slash") {
                Button("skip-worktree (keep my local version)") { chooseFiles(.skipWorktree) }
                    .hint(HiddenFileRowMapper.skipWorktreeHint)
                Button("assume-unchanged (speed hint)") { chooseFiles(.assumeUnchanged) }
                    .hint(HiddenFileRowMapper.assumeUnchangedHint)
            }
            .menuStyle(.borderlessButton)
            .controlSize(.small)
            .font(.caption)
            .fixedSize()
            .disabled(hidden.busyTitle != nil)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var content: some View {
        ListState(
            failure: hidden.files.isEmpty ? hidden.error.map { error in
                ListMessage.failure("Cannot read hidden files", description: error, actionTitle: nil)
            } : nil,
            isLoading: hidden.files.isEmpty && hidden.isLoading,
            loadingTitle: "Reading hidden files…",
            empty: hidden.files.isEmpty
                ? ListMessage("No hidden files", systemImage: "eye", description: "Hide a file to keep local changes out of git status, for example a local config. Use \"Hide Changes from Git\" in the menu of a changed file, or \"Hide a File…\" above.")
                : nil,
            noResultsFor: hidden.files.isEmpty == false && visibleFiles.isEmpty ? session.searchText : nil
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(visibleFiles) { file in
                        HiddenFileRow(
                            model: rowModel(file),
                            onToggleDiff: { hidden.toggleDiff(file) },
                            onTrack: { hidden.track(file, mode: $0) }
                        )
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var visibleFiles: [GitHiddenFile] {
        hidden.files.filter { session.matchesSearch($0.path) }
    }

    private func chooseFiles(_ flag: GitHiddenFlag) {
        let urls = FolderPicker.chooseFiles(
            directory: URL(fileURLWithPath: git.checkoutPath),
            prompt: "Hide",
            message: "Choose tracked files of this checkout. git stops showing their changes (\(flag.name)).",
            extensions: []
        )
        hidden.hide(filesAt: urls, flag: flag)
    }

    private func rowModel(_ file: GitHiddenFile) -> HiddenFileRowModel {
        HiddenFileRowMapper.model(
            for: file,
            checkoutPath: git.checkoutPath,
            isExpanded: hidden.expandedIDs.contains(file.id),
            diff: hidden.diffs[file.id],
            isBusy: hidden.busyTitle != nil,
            syntaxColors: settings.values.diffSyntaxColors
        )
    }
}

#Preview {
    HiddenSection()
        .previewEnvironment()
}
