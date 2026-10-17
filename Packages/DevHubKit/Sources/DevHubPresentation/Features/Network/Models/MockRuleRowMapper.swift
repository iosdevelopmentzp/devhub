import Foundation
import DevHubDomain
import DevHubUI

enum MockRuleRowMapper {

    static func model(for rule: MockRule, isEditing: Bool) -> MockRuleRowModel {
        let method = rule.method?.trimmed.uppercased() ?? ""
        return MockRuleRowModel(
            id: rule.id,
            method: method.isEmpty ? "ANY" : method,
            methodTint: method.isEmpty ? .gray : NetworkRequestRowMapper.methodTint(method),
            path: rule.query.map { "\(rule.pathPattern)?\($0)" } ?? rule.pathPattern,
            summary: summary(of: rule.action),
            summaryTint: rule.isEnabled ? .purple : .secondary,
            isEnabled: rule.isEnabled,
            isEditing: isEditing
        )
    }

    static func summary(of action: MockAction) -> String {
        var parts: [String]
        switch action {
        case .respond(let response):
            parts = ["Respond \(response.status)"]
            if response.body.isEmpty == false {
                parts.append(ByteFormat.text(Int64(response.body.utf8.count)))
            }
        case .patch(let patch):
            parts = ["Patch \(CountText.count(patch.operations.count, "key"))"]
        }
        if action.delay > 0 {
            parts.append("\(DurationFormat.text(action.delay)) delay")
        }
        return parts.joined(separator: " · ")
    }
}
