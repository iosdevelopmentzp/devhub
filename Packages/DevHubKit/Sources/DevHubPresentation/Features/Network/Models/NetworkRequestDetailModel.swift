import Foundation
import DevHubDomain
import DevHubUI

struct NetworkRequestDetailModel: Equatable {
    var url: String
    var statusLine: String
    var statusTint: Tint
    var error: String?
    var requestBody: String?
    var responseBody: String?
    var headers: [HTTPHeader]
    var requestHeaders: [HTTPHeader]
    var sourceNote: String?
    var graphQLOperations: [String]
    var graphQLVariables: String?
    var graphQLErrors: [String]
    var canMock: Bool
    var curl: String
    var rawResponseBody: String
    var canCopyResponseBody: Bool

    static let preview = NetworkRequestDetailModel(
        url: "https://api-qa.example.com/v1/profile/info",
        statusLine: "200 no error · GET · 182 ms",
        statusTint: .green,
        error: nil,
        requestBody: nil,
        responseBody: "{\n  \"data\" : {\n    \"name\" : \"Test User\"\n  }\n}",
        headers: [HTTPHeader(name: "Content-Type", value: "application/json")],
        requestHeaders: [HTTPHeader(name: "Accept", value: "application/json")],
        sourceNote: "Forwarded by DevHub to api-qa.example.com",
        graphQLOperations: [],
        graphQLVariables: nil,
        graphQLErrors: [],
        canMock: true,
        curl: "curl 'https://api-qa.example.com/v1/profile/info'",
        rawResponseBody: #"{"data":{"name":"Test User"}}"#,
        canCopyResponseBody: true
    )
}
