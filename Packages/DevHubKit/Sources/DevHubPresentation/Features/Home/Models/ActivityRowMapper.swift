import Foundation
import DevHubDomain
import DevHubUI

enum ActivityRowMapper {

    static func model(for event: ActivityEvent) -> ActivityRowModel {
        ActivityRowModel(
            id: event.id,
            title: event.title,
            detail: event.detail,
            dateText: event.date.relativeDescription,
            dotTint: dotTint(for: event.outcome),
            dotOpacity: event.outcome == .info ? 0.5 : 1
        )
    }

    private static func dotTint(for outcome: ActivityEvent.Outcome) -> Tint {
        switch outcome {
        case .success: .green
        case .failure: .red
        case .info: .secondary
        }
    }
}
