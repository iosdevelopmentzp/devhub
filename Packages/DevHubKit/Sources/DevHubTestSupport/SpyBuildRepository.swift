import DevHubDomain
import Foundation

package final class SpyBuildRepository: BuildRepository, @unchecked Sendable {
    package enum Call: Equatable {
        case schemes(projectPath: String)
        case listedSchemes(projectPath: String)
        case clean(BuildRequest)
        case build(BuildRequest)
        case locateProduct(BuildRequest, hints: [String])
        case lastBuiltAppPath(projectPath: String, scheme: String, configuration: String)
        case product(appPath: String)

        package static func == (lhs: Call, rhs: Call) -> Bool {
            switch (lhs, rhs) {
            case let (.schemes(left), .schemes(right)), let (.listedSchemes(left), .listedSchemes(right)):
                left == right
            case let (.clean(left), .clean(right)), let (.build(left), .build(right)):
                same(left, right)
            case let (.locateProduct(left, leftHints), .locateProduct(right, rightHints)):
                same(left, right) && leftHints == rightHints
            case let (.product(left), .product(right)):
                left == right
            case let (.lastBuiltAppPath(leftPath, leftScheme, leftConfiguration), .lastBuiltAppPath(rightPath, rightScheme, rightConfiguration)):
                leftPath == rightPath && leftScheme == rightScheme && leftConfiguration == rightConfiguration
            default:
                false
            }
        }

        private static func same(_ left: BuildRequest, _ right: BuildRequest) -> Bool {
            left.projectPath == right.projectPath
                && left.container == right.container
                && left.scheme == right.scheme
                && left.configuration == right.configuration
                && left.incremental == right.incremental
                && left.simulatorUDID == right.simulatorUDID
                && left.simulatorName == right.simulatorName
                && left.launch == right.launch
                && left.cleanInstall == right.cleanInstall
                && left.attachDebugger == right.attachDebugger
                && left.launchesApp == right.launchesApp
        }
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _schemesResult: [String] = []
    private var _listedSchemesResult: Result<[String], any Error> = .success([])
    private var _cleanEvents: [BuildEvent] = []
    private var _cleanError: (any Error)? = nil
    private var _buildEvents: [BuildEvent] = []
    private var _buildHints: [String] = []
    private var _buildError: (any Error)? = nil
    private var _locateProductResult: Result<BuildProduct, any Error> = .success(BuildProduct(appPath: "", bundleID: ""))
    private var _lastBuiltAppPathResult: String? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var schemesResult: [String] {
        get { lock.withLock { _schemesResult } }
        set { lock.withLock { _schemesResult = newValue } }
    }

    package var listedSchemesResult: Result<[String], any Error> {
        get { lock.withLock { _listedSchemesResult } }
        set { lock.withLock { _listedSchemesResult = newValue } }
    }

    package var cleanEvents: [BuildEvent] {
        get { lock.withLock { _cleanEvents } }
        set { lock.withLock { _cleanEvents = newValue } }
    }

    package var cleanError: (any Error)? {
        get { lock.withLock { _cleanError } }
        set { lock.withLock { _cleanError = newValue } }
    }

    package var buildEvents: [BuildEvent] {
        get { lock.withLock { _buildEvents } }
        set { lock.withLock { _buildEvents = newValue } }
    }

    package var buildHints: [String] {
        get { lock.withLock { _buildHints } }
        set { lock.withLock { _buildHints = newValue } }
    }

    package var buildError: (any Error)? {
        get { lock.withLock { _buildError } }
        set { lock.withLock { _buildError = newValue } }
    }

    package var locateProductResult: Result<BuildProduct, any Error> {
        get { lock.withLock { _locateProductResult } }
        set { lock.withLock { _locateProductResult = newValue } }
    }

    package var lastBuiltAppPathResult: String? {
        get { lock.withLock { _lastBuiltAppPathResult } }
        set { lock.withLock { _lastBuiltAppPathResult = newValue } }
    }

    package func schemes(projectPath: String, container: String?) async -> [String] {
        record(.schemes(projectPath: projectPath)) { _schemesResult }
    }

    package func listedSchemes(projectPath: String, container: String?) async throws -> [String] {
        try record(.listedSchemes(projectPath: projectPath)) { try _listedSchemesResult.get() }
    }

    package func clean(_ request: BuildRequest, onEvent: @escaping @Sendable (BuildEvent) -> Void) async throws {
        let (events, error) = record(.clean(request)) { (_cleanEvents, _cleanError) }
        events.forEach(onEvent)
        if let error { throw error }
    }

    package func build(_ request: BuildRequest, onEvent: @escaping @Sendable (BuildEvent) -> Void) async throws -> [String] {
        let (events, hints, error) = record(.build(request)) { (_buildEvents, _buildHints, _buildError) }
        events.forEach(onEvent)
        if let error { throw error }
        return hints
    }

    package func locateProduct(_ request: BuildRequest, hints: [String]) async throws -> BuildProduct {
        try record(.locateProduct(request, hints: hints)) { try _locateProductResult.get() }
    }

    package func product(atAppPath path: String) throws -> BuildProduct {
        try record(.product(appPath: path)) { try _locateProductResult.get() }
    }

    package func lastBuiltAppPath(projectPath: String, container: String?, scheme: String, configuration: String) -> String? {
        record(.lastBuiltAppPath(projectPath: projectPath, scheme: scheme, configuration: configuration)) { _lastBuiltAppPathResult }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
