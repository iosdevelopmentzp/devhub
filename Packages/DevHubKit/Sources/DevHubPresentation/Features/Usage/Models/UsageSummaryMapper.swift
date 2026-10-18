import Foundation
import DevHubDomain
import DevHubUI

enum UsageSummaryMapper {

    static func model(for usage: ClaudeUsage, now: Date) -> UsageSummaryModel {
        UsageSummaryModel(
            meters: usage.limits.map { UsageMeterMapper.model(for: $0, now: now) },
            planTag: TagModel(usage.plan, tint: .indigo, systemImage: "person.2"),
            updatedText: "Updated \(usage.updatedAt.relativeDescription)",
            note: nil
        )
    }

    static func model(for usage: CopilotUsage, now: Date) -> UsageSummaryModel {
        UsageSummaryModel(
            meters: usage.limits.map { UsageMeterMapper.model(for: $0, now: now) },
            planTag: TagModel(usage.plan ?? "Copilot", tint: .indigo, systemImage: "person.2"),
            updatedText: "Updated \(usage.updatedAt.relativeDescription)",
            note: usage.isUnlimited ? "No premium request limit" : nil
        )
    }
}
