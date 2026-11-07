import Testing
@testable import DevHubDomain

@Suite struct ActionConfirmationPolicyTests {
    private let environment = ActionInput(key: "env", title: "Environment", type: .choice, options: [
        InputOption(value: "/qabot", title: "QA"),
        InputOption(value: "/prodbot", title: "PROD", confirm: "Send to PROD?"),
    ])

    @Test func theChosenOptionConfirmationWinsOverTheActionText() {
        let action = ActionConfig(id: "x", title: "X", run: .open("x"), inputs: [environment], confirm: "Run it?")

        #expect(ActionConfirmationPolicy.text(for: action, sharedInputs: [], values: ["env": "/prodbot"]) == "Send to PROD?")
        #expect(ActionConfirmationPolicy.text(for: action, sharedInputs: [], values: ["env": "/qabot"]) == "Run it?")
        #expect(ActionConfirmationPolicy.text(for: action, sharedInputs: [], values: [:]) == "Run it?")
    }

    @Test func aSharedChoiceAsksToo() {
        let action = ActionConfig(id: "x", title: "X", run: .copy("{env} coins", open: nil))

        #expect(ActionConfirmationPolicy.text(for: action, sharedInputs: [environment], values: ["env": "/prodbot"]) == "Send to PROD?")
        #expect(ActionConfirmationPolicy.text(for: action, sharedInputs: [environment], values: ["env": "/qabot"]) == nil)
    }

    @Test func needsPromptForInputsOrAConfirmation() {
        let plain = ActionConfig(id: "x", title: "X", run: .open("x"))
        let withInputs = ActionConfig(id: "y", title: "Y", run: .open("x"), inputs: [ActionInput(key: "n", title: "N", type: .text)])

        #expect(ActionConfirmationPolicy.needsPrompt(plain, sharedInputs: [], values: [:]) == false)
        #expect(ActionConfirmationPolicy.needsPrompt(plain, sharedInputs: [environment], values: ["env": "/prodbot"]))
        #expect(ActionConfirmationPolicy.needsPrompt(plain, sharedInputs: [environment], values: ["env": "/qabot"]) == false)
        #expect(ActionConfirmationPolicy.needsPrompt(withInputs, sharedInputs: [], values: [:]))
    }
}
