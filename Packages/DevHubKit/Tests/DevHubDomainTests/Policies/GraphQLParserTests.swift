import Testing
@testable import DevHubDomain

@Suite struct GraphQLParserTests {

    @Test func aPostBodyGivesTheOperationNameKindAndVariables() throws {
        let body = #"{"operationName":"GetProfile","query":"query GetProfile($id: ID!) { profile(id: $id) { name } }","variables":{"id":"42"}}"#

        let exchange = try #require(GraphQLParser.exchange(method: "POST", query: nil, requestBody: body, responseBody: #"{"data":{}}"#))

        #expect(exchange.operations == [GraphQLOperation(name: "GetProfile", kind: .query, variables: "{\n  \"id\" : \"42\"\n}")])
        #expect(exchange.errors.isEmpty)
        #expect(exchange.title == "GetProfile")
    }

    @Test func theNameComesFromTheDocumentWhenOperationNameIsMissing() {
        #expect(GraphQLParser.operations(body: #"{"query":"mutation SaveCart { save }"}"#) == [GraphQLOperation(name: "SaveCart", kind: .mutation, variables: nil)])
        #expect(GraphQLParser.operations(body: #"{"query":"{ me { id } }"}"#) == [GraphQLOperation(name: nil, kind: .query, variables: nil)])
    }

    @Test func aBatchGivesEveryOperation() throws {
        let body = #"[{"query":"query A { a }"},{"query":"query B { b }"}]"#

        let exchange = try #require(GraphQLParser.exchange(method: "POST", query: nil, requestBody: body, responseBody: ""))

        #expect(exchange.operationNames == ["A", "B"])
        #expect(exchange.title == "A, B")
    }

    @Test func aPersistedQueryHasOnlyTheName() {
        let body = #"{"operationName":"GetFeed","extensions":{"persistedQuery":{"version":1,"sha256Hash":"abc"}}}"#

        #expect(GraphQLParser.operations(body: body).map(\.name) == ["GetFeed"])
    }

    @Test func aGetRequestReadsTheQueryString() {
        let operations = GraphQLParser.operations(query: "query=query%20GetProfile%20%7B%20name%20%7D&variables=%7B%22id%22%3A1%7D")

        #expect(operations == [GraphQLOperation(name: "GetProfile", kind: .query, variables: #"{"id":1}"#)])
    }

    @Test func restRequestsAreNotGraphQL() {
        #expect(GraphQLParser.exchange(method: "POST", query: nil, requestBody: #"{"name":"sam"}"#, responseBody: "") == nil)
        #expect(GraphQLParser.exchange(method: "GET", query: "page=2", requestBody: "", responseBody: "") == nil)
        #expect(GraphQLParser.exchange(method: "POST", query: nil, requestBody: "not json", responseBody: "") == nil)
    }

    @Test func errorsComeFromTheResponse() {
        #expect(GraphQLParser.errors(responseBody: #"{"data":null,"errors":[{"message":"Not allowed"},{"path":["x"]}]}"#) == ["Not allowed", "Unknown GraphQL error"])
        #expect(GraphQLParser.errors(responseBody: #"{"data":{}}"#).isEmpty)
        #expect(GraphQLParser.errors(responseBody: "").isEmpty)
    }
}
