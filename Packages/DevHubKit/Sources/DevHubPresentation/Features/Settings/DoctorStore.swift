import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class DoctorStore {
    private(set) var statuses: [ToolStatus] = []
    private(set) var codeHostAccess: CodeHostAccessCheck?
    private(set) var isChecking = false
    private(set) var isAccessibilityTrusted = false

    @ObservationIgnored private let checkTools: CheckToolsUseCase
    @ObservationIgnored private let attacher: any XcodeAttaching
    @ObservationIgnored private let repository: any CodeHostRepository
    @ObservationIgnored private let remote: any CodeHostLookup

    init(checkTools: CheckToolsUseCase, attacher: any XcodeAttaching, repository: any CodeHostRepository, remote: any CodeHostLookup) {
        self.checkTools = checkTools
        self.attacher = attacher
        self.repository = repository
        self.remote = remote
    }

    func check() async {
        guard isChecking == false else { return }
        isChecking = true
        isAccessibilityTrusted = attacher.isTrusted
        async let access = readAccess()
        let loaded = await checkTools.execute(DoctorPolicy.tools)
        if loaded != statuses {
            statuses = loaded
        }
        let checked = await access
        if checked != codeHostAccess {
            codeHostAccess = checked
        }
        isChecking = false
    }

    func requestAccessibility() {
        attacher.requestTrust()
        isAccessibilityTrusted = attacher.isTrusted
    }

    private func readAccess() async -> CodeHostAccessCheck? {
        guard let host = try? await remote.codeHost() else { return nil }
        do {
            return CodeHostAccessCheck(host: host, result: .success(try await repository.access(repository: host)))
        } catch let error as PullRequestError {
            return CodeHostAccessCheck(host: host, result: .failure(error))
        } catch {
            return CodeHostAccessCheck(host: host, result: .failure(.command(error.localizedDescription)))
        }
    }
}
