import Foundation

extension WorktreesStore {
    func candidates(matching query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let local = branches.local.filter { $0.worktreePath == nil }.map(\.name)
        let remote = branches.remote.map(\.name).filter { branches.hasLocal($0) == false }
        let all = local + remote
        guard trimmed.isEmpty == false else { return Array(all.prefix(8)) }
        return Array(all.filter { $0.localizedCaseInsensitiveContains(trimmed) }.prefix(8))
    }

    func creation(for name: String) -> WorktreeCreation {
        if branches.hasLocal(name) { return .local(name) }
        if branches.hasRemote(name) { return .remote(name) }
        return .new(name)
    }

    func createWorktree(named input: String) async -> Bool {
        let name = input.trimmingCharacters(in: .whitespaces)
        setCreationError(nil)
        guard name.isEmpty == false else {
            setCreationError("Type a branch name.")
            return false
        }
        do {
            _ = try await makeWorktree(branch: name)
            return true
        } catch {
            setCreationError(error.localizedDescription)
            executor.fail("Create worktree", message: error.localizedDescription)
            return false
        }
    }

    func checkoutPath(forBranch branch: String) async throws -> String {
        guard mainPath != nil else {
            throw WorktreeFailure(message: "No project is selected.")
        }
        if worktrees.isEmpty {
            await refresh()
        }
        if let existing = worktree(forBranch: branch) {
            return existing.path
        }
        return try await makeWorktree(branch: branch)
    }

    func runBootstrap(path: String) async {
        guard let script = worktreeSettings?.bootstrap else { return }
        markBusy(path, true)
        defer { markBusy(path, false) }
        do {
            let code = try await provider.runBootstrap(script: script, at: path)
            if code == 0 {
                activity.log("Bootstrap", detail: path, outcome: .success)
            } else {
                executor.fail("Bootstrap", message: "The script exited with code \(code).")
            }
        } catch {
            executor.fail("Bootstrap", message: error.localizedDescription)
        }
        await refresh()
    }

    private func makeWorktree(branch name: String) async throws -> String {
        guard let main = mainPath else {
            throw WorktreeFailure(message: "No project is selected.")
        }
        guard await executor.succeeds(.checkRefFormat(name), at: main) else {
            throw WorktreeFailure(message: "\(name) is not a valid branch name.")
        }
        let creation = creation(for: name)
        if let taken = branches.local(named: name)?.worktreePath {
            throw WorktreeFailure(message: "\(name) is already checked out at \(taken).")
        }
        let path = WorktreeLocation.path(repository: main, folder: worktreeSettings?.folder, branch: name)
        guard FileManager.default.fileExists(atPath: path) == false else {
            throw WorktreeFailure(message: "The folder \(path) already exists.")
        }
        setWorking("Creating worktree for \(name)")
        defer { setWorking(nil) }
        guard await executor.perform(.worktreeAdd(creation, path: path, base: baseBranch), at: main, title: "Create worktree for \(name)") != nil else {
            throw WorktreeFailure(message: "git worktree add failed. See the Output panel.")
        }
        await prepare(path: path, main: main)
        await refresh()
        announceChange()
        toaster.show("Worktree ready: \(name)", tint: .green)
        return path
    }

    private func prepare(path: String, main: String) async {
        let settings = worktreeSettings
        if let include = settings?.include, include.isEmpty == false {
            do {
                let copied = try await provider.copyIncludes(from: main, to: path, paths: include)
                activity.log("Copy worktree files", detail: copied.isEmpty ? "Nothing to copy." : copied.joined(separator: ", "), outcome: .success)
            } catch {
                executor.fail("Copy worktree files", message: error.localizedDescription)
            }
        }
        guard let script = settings?.bootstrap else { return }
        let marker = settings?.bootstrapMarker
        let manager = FileManager.default
        let due = marker.map { manager.fileExists(atPath: main + "/" + $0) && manager.fileExists(atPath: path + "/" + $0) == false } ?? true
        guard due else { return }
        setWorking("Bootstrapping \(URL(fileURLWithPath: path).lastPathComponent)")
        do {
            let code = try await provider.runBootstrap(script: script, at: path)
            if code == 0 {
                activity.log("Bootstrap", detail: path, outcome: .success)
            } else {
                executor.fail("Bootstrap", message: "The script exited with code \(code).")
            }
        } catch {
            executor.fail("Bootstrap", message: error.localizedDescription)
        }
    }
}
