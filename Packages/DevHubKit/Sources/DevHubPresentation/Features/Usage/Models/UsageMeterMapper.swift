import Foundation
import DevHubDomain
import DevHubUI

enum UsageMeterMapper {

    static func model(for limit: UsageLimit, now: Date) -> UsageMeterModel {
        UsageMeterModel(
            id: limit.id,
            title: limit.title,
            percentText: limit.percentText,
            fraction: limit.usedFraction,
            levelTint: levelTint(for: limit.usedFraction),
            resetText: resetText(for: limit.resetsAt, now: now)
        )
    }

    private static func levelTint(for usedFraction: Double) -> Tint? {
        if usedFraction >= 0.85 { return .red }
        if usedFraction >= 0.6 { return .orange }
        return nil
    }

    private static func resetText(for resetsAt: Date?, now: Date) -> String {
        guard let resetsAt else { return "No reset scheduled" }
        let interval = resetsAt.timeIntervalSince(now)
        if interval < 86400, let countdown = Countdown.text(interval) {
            return "Resets in \(countdown)"
        }
        return "Resets \(resetsAt.formatted(.dateTime.weekday(.abbreviated).hour().minute()))"
    }
}
