import Foundation

nonisolated enum UsageHTTP {
    static func get(_ url: URL, headers: [String: String]) async throws -> (Data, Int) {
        var request = URLRequest(url: url, timeoutInterval: 15)
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
}
