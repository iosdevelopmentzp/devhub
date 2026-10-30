import Foundation

enum SchemeEditorMapper {

    static func model(manual: [String], suggestions: [String], isLoaded: Bool, isLoading: Bool) -> SchemeEditorModel {
        SchemeEditorModel(
            manual: manual,
            suggestions: suggestions,
            message: message(hasSuggestions: suggestions.isEmpty == false, isLoaded: isLoaded, isLoading: isLoading),
            isLoading: isLoading
        )
    }

    private static func message(hasSuggestions: Bool, isLoaded: Bool, isLoading: Bool) -> String? {
        if isLoading { return "Reading the schemes and targets of the project…" }
        guard isLoaded, hasSuggestions == false else { return nil }
        return "Every scheme and target of the project is in the list. Type a name to add another one."
    }
}
