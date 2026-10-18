import Foundation
import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct NetworkRequestDetailMapperTests {
    @Test func mapsTheProfileRequest() {
        let model = NetworkRequestDetailMapper.model(for: NetworkRequestFixture.profile)

        #expect(model.url == "https://api-qa.example.com/v1/profile/info")
        #expect(model.statusLine == "200 no error · GET · 182 ms")
        #expect(model.statusTint == .green)
        #expect(model.error == nil)
        #expect(model.requestBody == nil)
        #expect(model.responseBody == "{\n  \"a\" : {\n    \"c\" : \"x/y\"\n  },\n  \"b\" : 1\n}")
        #expect(model.headers == [HTTPHeader(name: "Content-Type", value: "application/json")])
        #expect(model.curl == "curl 'https://api-qa.example.com/v1/profile/info'")
        #expect(model.rawResponseBody == #"{"b":1,"a":{"c":"x/y"}}"#)
        #expect(model.canCopyResponseBody)
    }

    @Test func aFailureWithoutResponseSaysFailed() {
        let request = NetworkRequestFixture.with(method: "", statusCode: nil, error: "timed out", isFailure: true, duration: nil)

        let model = NetworkRequestDetailMapper.model(for: request)

        #expect(model.statusLine == "Failed")
        #expect(model.statusTint == .red)
        #expect(model.error == "timed out")
    }

    @Test func aMissingResponseAndEmptyBodyCannotBeCopied() {
        var request = NetworkRequestFixture.with(method: "GET", statusCode: nil, error: nil, isFailure: false, duration: nil)
        request.responseBody = ""

        let model = NetworkRequestDetailMapper.model(for: request)

        #expect(model.statusLine == "No response yet · GET")
        #expect(model.responseBody == nil)
        #expect(model.canCopyResponseBody == false)
    }

    @Test func aHugeBodyIsCutWithANote() throws {
        var request = NetworkRequestFixture.profile
        request.responseBody = String(repeating: "x", count: NetworkRequestDetailMapper.bodyLimit + 10)

        let body = try #require(NetworkRequestDetailMapper.model(for: request).responseBody)

        #expect(body.hasPrefix(String(repeating: "x", count: NetworkRequestDetailMapper.bodyLimit) + "\n…"))
        #expect(body.contains("Copy the body"))
    }

    @Test func sourceNoteAndRequestHeaders() {
        var request = NetworkRequestFixture.profile
        request.requestHeaders = [HTTPHeader(name: "Accept", value: "*/*")]
        let forwarded = NetworkRequestDetailMapper.model(for: request)
        request.mockRuleID = UUID()

        #expect(forwarded.sourceNote == "Forwarded by DevHub to api-qa.example.com")
        #expect(forwarded.requestHeaders == [HTTPHeader(name: "Accept", value: "*/*")])
        #expect(NetworkRequestDetailMapper.model(for: request).sourceNote == "Answered by a DevHub mock rule")
    }

    @Test func requestWithoutMethodCannotBeMocked() {
        #expect(NetworkRequestDetailMapper.model(for: NetworkRequestFixture.profile).canMock)
        #expect(NetworkRequestDetailMapper.model(for: NetworkRequestFixture.with(method: "", statusCode: nil, error: "x", isFailure: true, duration: nil)).canMock == false)
    }

    @Test func aGraphQLRequestListsItsOperationsVariablesAndErrors() {
        var request = NetworkRequestFixture.profile
        request.graphQL = GraphQLExchange(operations: [GraphQLOperation(name: "GetProfile", kind: .query, variables: "{\"id\":1}")], errors: ["Not found"])

        let model = NetworkRequestDetailMapper.model(for: request)

        #expect(model.graphQLOperations == ["query GetProfile"])
        #expect(model.graphQLVariables == "{\"id\":1}")
        #expect(model.graphQLErrors == ["Not found"])
        #expect(NetworkRequestDetailMapper.model(for: NetworkRequestFixture.profile).graphQLOperations.isEmpty)
    }
}
