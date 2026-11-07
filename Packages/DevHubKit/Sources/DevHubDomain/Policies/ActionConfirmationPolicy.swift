import Foundation

package enum ActionConfirmationPolicy {

    package static func text(for action: ActionConfig, sharedInputs: [ActionInput], values: [String: String]) -> String? {
        for input in (action.inputs ?? []) + sharedInputs where input.type == .choice {
            guard let value = values[input.key], let option = input.options?.first(where: { $0.value == value }), let confirm = option.confirm else { continue }
            return confirm
        }
        return action.confirm
    }

    package static func needsPrompt(_ action: ActionConfig, sharedInputs: [ActionInput], values: [String: String]) -> Bool {
        (action.inputs ?? []).isEmpty == false || text(for: action, sharedInputs: sharedInputs, values: values) != nil
    }
}
