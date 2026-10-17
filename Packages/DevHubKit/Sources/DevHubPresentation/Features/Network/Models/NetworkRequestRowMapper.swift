import Foundation
import DevHubDomain
import DevHubUI

enum NetworkRequestRowMapper {

    static func model(for request: NetworkRequest, isSelected: Bool) -> NetworkRequestRowModel {
        NetworkRequestRowModel(
            id: request.id,
            method: request.method.isEmpty ? "?" : request.method.uppercased(),
            methodTint: methodTint(request.method),
            path: request.path.isEmpty ? request.url : request.path,
            host: request.host,
            status: status(of: request),
            statusTint: statusTint(of: request),
            statusHint: statusHint(of: request),
            duration: request.duration.map(DurationFormat.text) ?? "",
            durationTint: NetworkRequestFilter.slow.matches(request) ? .orange : .secondary,
            time: LogTimestamp.text(request.startedAt),
            tags: tags(for: request),
            isSelected: isSelected
        )
    }

    static let mockedTag = TagModel("mocked", tint: .purple, systemImage: "theatermasks", hint: "A DevHub mock rule answered or changed this response")
    static let passthroughTag = TagModel("via DevHub", tint: .indigo, systemImage: "arrow.left.arrow.right", hint: "The DevHub mock server forwarded this request to the real host")

    static func tags(for request: NetworkRequest) -> [TagModel] {
        return [request.mockRuleID == nil ? passthroughTag : mockedTag]
    }

    static func methodTint(_ method: String) -> Tint {
        switch method.uppercased() {
        case "GET": .blue
        case "POST": .green
        case "PUT", "PATCH": .orange
        case "DELETE": .red
        default: .gray
        }
    }

    static func statusTint(of request: NetworkRequest) -> Tint {
        if request.error != nil { return .red }
        guard let code = request.statusCode else { return request.isFailure ? .red : .gray }
        switch code {
        case 200..<300: return .green
        case 300..<500: return .orange
        default: return .red
        }
    }

    static func status(of request: NetworkRequest) -> String {
        if let code = request.statusCode { return String(code) }
        return request.error == nil ? "—" : "Failed"
    }

    static func statusHint(of request: NetworkRequest) -> String {
        if let error = request.error { return error }
        guard let code = request.statusCode else { return "No response yet" }
        return request.statusText.isEmpty ? String(code) : "\(code) \(request.statusText)"
    }
}
