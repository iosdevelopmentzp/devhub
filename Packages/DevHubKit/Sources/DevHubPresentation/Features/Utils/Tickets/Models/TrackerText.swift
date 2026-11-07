import Foundation

enum TrackerText {
    static let installCommand = "brew install jira-cli"
    static let setupCommand = "jira init"
    static let tokenCommand = "security add-generic-password -s jira-cli -a <your login> -w <api token>"
    static let noTrackerTitle = "No tracker for this project"
    static let noTrackerDescription = "Add \"tracker\": { \"kind\": \"jira\", \"project\": \"ABC\" } to .devhub/project.json. A git.ticketURL that points at Jira turns this tab on too."
}
