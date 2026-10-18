import SwiftUI
import DevHubDomain
import DevHubUI

struct NetworkRequestDetail: View {
    @Environment(Toaster.self) private var toaster

    let model: NetworkRequestDetailModel
    let onMockThis: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.url)
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .copyOnClick(model.url, label: "URL")
            HStack(spacing: 8) {
                Text(model.statusLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(model.statusTint.color)
                Spacer(minLength: 6)
                Button("Copy as cURL", systemImage: "terminal") {
                    toaster.copy(model.curl, label: "cURL command")
                }
                .fixedSize()
                .hint("Copy a curl command for this request. Request headers are not in the log, so add the token by hand.")
                Button("Copy Response Body", systemImage: "doc.on.doc") {
                    toaster.copy(model.rawResponseBody, label: "response body")
                }
                .fixedSize()
                .disabled(model.canCopyResponseBody == false)
                if let onMockThis {
                    Button("Mock This", systemImage: "theatermasks", action: onMockThis)
                        .fixedSize()
                        .disabled(model.canMock == false)
                        .hint("Add a rule to the current mock set that answers this method and path (and GraphQL operation) with this status and body. The rule opens in the editor.")
                }
            }
            .controlSize(.small)
            if let sourceNote = model.sourceNote {
                Text(sourceNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let error = model.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
            if model.graphQLOperations.isEmpty == false {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GraphQL")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(model.graphQLOperations, id: \.self) { operation in
                        Text(operation)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                    ForEach(model.graphQLErrors, id: \.self) { error in
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Tint.red.color)
                            .textSelection(.enabled)
                    }
                }
            }
            if let variables = model.graphQLVariables {
                section("GraphQL variables", text: variables)
            }
            if let requestBody = model.requestBody {
                section("Request body", text: requestBody)
            }
            if let responseBody = model.responseBody {
                section("Response body", text: responseBody)
            }
            if model.requestHeaders.isEmpty == false {
                headers("Request headers", model.requestHeaders)
            }
            if model.headers.isEmpty == false {
                headers("Response headers", model.headers)
            }
        }
        .padding(.leading, 76)
        .padding(.trailing, 14)
        .padding(.vertical, 10)
        .background(Theme.base)
    }

    private func headers(_ title: String, _ headers: [HTTPHeader]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(header.name)
                        .font(.caption2.monospaced().weight(.semibold))
                        .fixedSize()
                    Text(header.value)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func section(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 10.5, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Theme.border))
        }
    }
}

#Preview {
    NetworkRequestDetail(model: .preview, onMockThis: {})
        .previewEnvironment()
        .frame(width: 720)
}
