import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct ScriptNetworkSourceRepositoryTests {
    @Test func linesBecomeEventsAndTheSameKeyKeepsItsID() async throws {
        let scripts = SpyScriptRunner()
        scripts.events = [
            .output(#"@devhub {"request": {"id": "a", "method": "GET", "url": "/v1/x"}}"#),
            .output(#"@devhub {"request": {"method": "GET", "url": "/v1/y"}}"#),
            .output(#"@devhub {"request": {"id": "a", "method": "GET", "url": "/v1/x", "status": 200}}"#),
            .output("token=abcdef1234567890abcdef"),
            .exited(0),
        ]
        let run = ScriptRunRequest(executable: "/repo/network/source.sh", arguments: [], cwd: "/repo", environment: [:])

        var events: [NetworkSourceEvent] = []
        for try await event in ScriptNetworkSourceRepository(scripts: scripts).follow(run) {
            events.append(event)
        }

        let ids = events.compactMap { event -> Int? in
            guard case let .request(request) = event else { return nil }
            return request.id
        }
        #expect(ids == [ScriptNetworkSourceRepository.firstID, ScriptNetworkSourceRepository.firstID + 1, ScriptNetworkSourceRepository.firstID])
        #expect(events.last == .exited(0))
        #expect(scripts.calls == [run])
        guard case let .output(line) = events[3] else {
            Issue.record("Not an output line")
            return
        }
        #expect(line.contains("abcdef1234567890abcdef") == false)
    }
}
