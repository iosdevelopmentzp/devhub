import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class DoctorStore {
    private(set) var statuses: [ToolStatus] = []
    private(set) var isChecking = false
    private(set) var isAccessibilityTrusted = false

    @ObservationIgnored private let checkTools: CheckToolsUseCase
    @ObservationIgnored private let attacher: any XcodeAttaching

    init(checkTools: CheckToolsUseCase, attacher: any XcodeAttaching) {
        self.checkTools = checkTools
        self.attacher = attacher
    }

    func check() async {
        guard isChecking == false else { return }
        isChecking = true
        isAccessibilityTrusted = attacher.isTrusted
        let loaded = await checkTools.execute(DoctorPolicy.tools)
        if loaded != statuses {
            statuses = loaded
        }
        isChecking = false
    }

    func requestAccessibility() {
        attacher.requestTrust()
        isAccessibilityTrusted = attacher.isTrusted
    }
}
