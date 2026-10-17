import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class ProjectSession {
    private(set) var projects: [Project] {
        didSet { save() }
    }
    var selectedProjectID: Project.ID {
        didSet {
            guard oldValue != selectedProjectID else { return }
            save()
            events.post(.projectChanged)
        }
    }
    var searchText = ""
    @ObservationIgnored private var savedSearches: [FeatureID: String] = [:]

    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let detector: any ProjectDetecting

    init(projects: [Project], selectedProjectID: Project.ID?, store: any KeyValueStore, events: AppEvents, detector: any ProjectDetecting) {
        self.projects = projects
        self.selectedProjectID = selectedProjectID.flatMap { id in projects.first { $0.id == id }?.id } ?? projects.first?.id ?? Project.none.id
        self.store = store
        self.events = events
        self.detector = detector
    }

    var selectedProject: Project {
        projects.first { $0.id == selectedProjectID } ?? projects.first ?? .none
    }

    var hasProject: Bool {
        projects.isEmpty == false
    }

    func switchSearch(from oldFeatureID: FeatureID, to newFeatureID: FeatureID) {
        savedSearches[oldFeatureID] = searchText
        searchText = savedSearches[newFeatureID] ?? ""
    }

    func matchesSearch(_ fields: String...) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard query.isEmpty == false else { return true }
        return fields.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    // MARK: Projects

    func addProject(at folder: URL) {
        add(detector.project(at: folder))
    }

    func add(_ project: Project) {
        if let existing = projects.first(where: { $0.path == project.path }) {
            selectedProjectID = existing.id
            return
        }
        projects.append(project)
        selectedProjectID = project.id
    }

    func update(_ project: Project) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        let schemeOrBundleChanged = projects[index].scheme != project.scheme || projects[index].bundleID != project.bundleID
        projects[index] = project
        if schemeOrBundleChanged, project.id == selectedProjectID {
            events.post(.projectChanged)
        }
    }

    func remove(id: Project.ID) {
        guard projects.count > 1 else { return }
        projects.removeAll { $0.id == id }
        if selectedProjectID == id {
            selectedProjectID = projects[0].id
        }
    }

    private func save() {
        store.encode(projects, forKey: PreferenceKeys.projects)
        store.set(selectedProjectID, forKey: PreferenceKeys.selectedProject)
    }
}
