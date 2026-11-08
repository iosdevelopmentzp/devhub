import Foundation
import DevHubDomain
import DevHubUI

enum NetworkRequestDetailMapper {
    static let bodyLimit = 50_000

    static func model(for request: NetworkRequest) -> NetworkRequestDetailModel {
        NetworkRequestDetailModel(
            url: request.url,
            statusLine: statusLine(for: request),
            statusTint: NetworkRequestRowMapper.statusTint(of: request),
            error: request.error,
            requestBody: body(request.requestBody),
            responseBody: body(request.responseBody),
            headers: request.responseHeaders,
            requestHeaders: request.requestHeaders,
            sourceNote: sourceNote(for: request),
            graphQLOperations: request.graphQL?.operations.map { "\($0.kind.rawValue) \($0.name ?? "(no name)")" } ?? [],
            graphQLVariables: request.graphQL.flatMap(variables),
            graphQLErrors: request.graphQL?.errors ?? [],
            canMock: request.isWebSocket == false && request.method.isEmpty == false && (request.path.isEmpty == false || request.url.isEmpty == false),
            curl: CurlCommandBuilder.command(for: request),
            rawResponseBody: request.responseBody,
            canCopyResponseBody: request.responseBody.isEmpty == false
        )
    }

    static func sourceNote(for request: NetworkRequest) -> String? {
        if request.origin == .sourceScript {
            return "Reported by network.sourceScript. The mock server did not see this request"
        }
        if request.isWebSocket {
            return "WebSocket passed through by DevHub to \(request.host). Messages are not mocked"
        }
        if request.mockRuleID != nil {
            return "Answered by a DevHub mock rule"
        }
        return "Forwarded by DevHub to \(request.host)"
    }

    private static func variables(_ graphQL: GraphQLExchange) -> String? {
        let all = graphQL.operations.compactMap(\.variables)
        return all.isEmpty ? nil : all.joined(separator: "\n")
    }

    private static func statusLine(for request: NetworkRequest) -> String {
        let status: String
        if let code = request.statusCode {
            status = request.statusText.isEmpty ? String(code) : "\(code) \(request.statusText)"
        } else {
            status = request.error == nil ? "No response yet" : "Failed"
        }
        let method = request.method.isEmpty ? nil : request.method.uppercased()
        let duration = request.duration.map(DurationFormat.text)
        return [status, method, duration].compactMap { $0 }.joined(separator: " · ")
    }

    private static func body(_ text: String) -> String? {
        guard text.isEmpty == false else { return nil }
        let pretty = JSONPrettyPrinter.format(text)
        guard pretty.count > bodyLimit else { return pretty }
        return String(pretty.prefix(bodyLimit)) + "\n… cut at \(bodyLimit) characters. Copy the body to see all of it."
    }
}
