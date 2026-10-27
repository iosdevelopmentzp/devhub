import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class KeepAwakeStore {
    private(set) var isActive = false

    @ObservationIgnored private let preventer: any SleepPreventing
    @ObservationIgnored private let activity: ActivityLog

    init(preventer: any SleepPreventing, activity: ActivityLog) {
        self.preventer = preventer
        self.activity = activity
    }

    func toggle() {
        if isActive {
            stop()
        } else {
            start()
        }
    }

    private func start() {
        do {
            try preventer.preventSleep(reason: "DevHub: Keep Mac awake")
            isActive = true
            activity.log("Keep Mac awake: on", detail: "The Mac does not sleep until you turn this off or quit DevHub", outcome: .info)
        } catch {
            activity.log("Could not keep the Mac awake", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func stop() {
        preventer.allowSleep()
        isActive = false
        activity.log("Keep Mac awake: off", detail: "The Mac can sleep again", outcome: .info)
    }
}
