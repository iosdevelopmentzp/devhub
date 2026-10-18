import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct FileMockSetRepositoryTests {
    private let directory: TemporaryDirectory
    private let repository: FileMockSetRepository

    init() throws {
        directory = try TemporaryDirectory()
        repository = FileMockSetRepository(root: directory.url)
    }

    @Test func roundTripKeepsEveryRuleField() async throws {
        let set = sample(name: "VIP user", body: #"{"ok":true}"#)

        try await repository.save(set, in: .defaultFolder(project: "example-app"))
        let loaded = try await repository.list(in: .defaultFolder(project: "example-app"))

        #expect(loaded == [set])
        #expect(FileManager.default.fileExists(atPath: directory.path("example-app/VIP-user.json")))
    }

    @Test func aConfiguredFolderIsUsedAsItIs() async throws {
        let set = sample(name: "Shared", body: "{}")
        let folder = directory.path("repo/Mocks")

        try await repository.save(set, in: .folder(folder))

        #expect(FileManager.default.fileExists(atPath: directory.path("repo/Mocks/Shared.json")))
        #expect(try await repository.list(in: .folder(folder)) == [set])
    }

    @Test func largeBodiesGoToBodyFilesNamedLikeTheUITestFixtures() async throws {
        let big = "{\"items\":[" + Array(repeating: #"{"name":"gift"}"#, count: 200).joined(separator: ",") + "]}"
        let set = sample(name: "Big", body: big)

        try await repository.save(set, in: .defaultFolder(project: "app"))

        #expect(FileManager.default.fileExists(atPath: directory.path("app/Big/bodies/GET_v1_settings_list.json")))
        #expect(try await repository.list(in: .defaultFolder(project: "app")) == [set])
    }

    @Test func renameMovesTheFileAndKeepsOneCopy() async throws {
        var set = sample(name: "First", body: "{}")
        try await repository.save(set, in: .defaultFolder(project: "app"))

        set.name = "Second"
        try await repository.save(set, in: .defaultFolder(project: "app"))

        #expect(try await repository.list(in: .defaultFolder(project: "app")).map(\.name) == ["Second"])
        #expect(FileManager.default.fileExists(atPath: directory.path("app/First.json")) == false)
    }

    @Test func twoSetsWithTheSameFileNameGetDifferentFiles() async throws {
        try await repository.save(sample(name: "A/B", body: "{}"), in: .defaultFolder(project: "app"))
        try await repository.save(sample(name: "A B", body: "{}"), in: .defaultFolder(project: "app"))

        #expect(try await repository.list(in: .defaultFolder(project: "app")).count == 2)
    }

    @Test func deleteRemovesTheFileAndItsBodies() async throws {
        let big = String(repeating: "x", count: 3_000)
        let set = sample(name: "Gone", body: big)
        try await repository.save(set, in: .defaultFolder(project: "app"))

        try await repository.delete(id: set.id, in: .defaultFolder(project: "app"))

        #expect(try await repository.list(in: .defaultFolder(project: "app")).isEmpty)
        #expect(FileManager.default.fileExists(atPath: directory.path("app/Gone")) == false)
    }

    @Test func missingFolderIsAnEmptyList() async throws {
        #expect(try await repository.list(in: .defaultFolder(project: "nothing")).isEmpty)
    }

    @Test func brokenFileIsReportedByName() async throws {
        _ = try directory.write("{ not json", to: "app/broken.json")

        await #expect(throws: MockSetError.unreadable(file: "broken.json", reason: "It is not a JSON object.")) {
            try await repository.list(in: .defaultFolder(project: "app"))
        }
    }

    @Test func noTokenEverReachesTheDisk() async throws {
        let secret = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.c2lnbmF0dXJl"
        let set = MockSet(id: UUID(), name: "Secrets", rules: [
            MockRule(
                id: UUID(),
                isEnabled: true,
                method: "GET",
                pathPattern: "/v1/auth",
                query: nil,
                action: .respond(MockResponse(
                    status: 200,
                    headers: [HTTPHeader(name: "Set-Cookie", value: "sid=\(secret)"), HTTPHeader(name: "Authorization", value: "Bearer \(secret)"), HTTPHeader(name: "X-Trace", value: "t1")],
                    body: #"{"access_token":"plain-secret-value","jwt":"\#(secret)"}"#,
                    delay: 0
                ))
            ),
            MockRule(
                id: UUID(),
                isEnabled: true,
                method: nil,
                pathPattern: "/v1/me",
                query: nil,
                action: .patch(MockPatch(operations: [JSONPatchOperation(keyPath: "data.token", value: "\"Bearer \(secret)\"")], delay: 0))
            )
        ])

        try await repository.save(set, in: .defaultFolder(project: "app"))

        let text = try String(contentsOfFile: directory.path("app/Secrets.json"), encoding: .utf8)
        #expect(text.contains(secret) == false)
        #expect(text.contains("plain-secret-value") == false)
        #expect(text.contains("Set-Cookie") == false)
        #expect(text.contains("Authorization") == false)
        #expect(text.contains("X-Trace"))
    }

    private func sample(name: String, body: String) -> MockSet {
        MockSet(id: UUID(), name: name, rules: [
            MockRule(
                id: UUID(),
                isEnabled: true,
                method: "GET",
                pathPattern: "/v1/settings/list",
                query: "lang=en",
                action: .respond(MockResponse(status: 200, headers: [HTTPHeader(name: "Content-Type", value: "application/json")], body: body, delay: 0.25))
            ),
            MockRule(
                id: UUID(),
                isEnabled: false,
                method: nil,
                pathPattern: "/v1/profile/**",
                query: nil,
                action: .patch(MockPatch(operations: [JSONPatchOperation(keyPath: "data.isVIP", value: "true"), JSONPatchOperation(keyPath: "data.banner", value: nil)], delay: 0))
            ),
            MockRule(
                id: UUID(),
                isEnabled: true,
                method: "POST",
                pathPattern: "/graphql",
                query: nil,
                action: .respond(MockResponse(status: 200, headers: [], body: #"{"data":{"profile":{"name":"sam"}}}"#, delay: 0)),
                operationName: "GetProfile"
            )
        ])
    }
}
