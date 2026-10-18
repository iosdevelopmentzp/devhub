import Foundation
import DevHubDomain
import DevHubUI

enum CustomTabMapper {

    static func sections(for tab: TabConfig, resolved: ResolvedConfig, placed: [CatalogAction], isVisible: (CatalogAction) -> Bool) -> [CustomTabSectionModel] {
        var sections = (tab.sections ?? []).enumerated().flatMap { index, section in
            models(for: section, index: index, resolved: resolved, isVisible: isVisible)
        }
        let listed = Set((tab.sections ?? []).flatMap { $0.actions ?? [] })
        let extra = placed.filter { listed.contains($0.id) == false }
        if extra.isEmpty == false {
            sections.append(CustomTabSectionModel(id: sections.count, title: "Actions", content: .actions(extra, missing: [])))
        }
        return sections
    }

    private static func models(for section: TabSection, index: Int, resolved: ResolvedConfig, isVisible: (CatalogAction) -> Bool) -> [CustomTabSectionModel] {
        var models: [CustomTabSectionModel] = []
        if let ids = section.actions, ids.isEmpty == false {
            let found = ids.compactMap { ActionCatalogPolicy.action(id: $0, resolved: resolved) }
            let missing = ids.filter { id in found.contains { $0.id == id } == false }
            let visible = found.filter(isVisible)
            if visible.isEmpty == false || missing.isEmpty == false {
                models.append(CustomTabSectionModel(id: index * 2, title: section.title, content: .actions(visible, missing: missing)))
            }
        }
        if let source = section.source {
            let id = CustomTabPolicy.sourceActionID(for: source)
            let content: CustomTabSectionModel.Content = resolved.action(id: id).map { .source($0, refresh: CustomTabPolicy.refresh(for: source)) } ?? .missingSource(source.script)
            models.append(CustomTabSectionModel(id: index * 2 + 1, title: section.title, content: content))
        }
        return models
    }
}
