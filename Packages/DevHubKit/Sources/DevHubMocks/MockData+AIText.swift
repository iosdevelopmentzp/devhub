import Foundation
import DevHubDomain

extension MockData {
    package static let aiCommitMessage = """
    feat(calls): add the gift value of a paid call

    Show the coins of a gift next to the call price, so the caller sees
    the full cost before the call starts.
    """

    package static let aiPullRequestText = """
    ABC-2324: Paid call payment

    ## What changes
    - Adds `GiftValue` with the coins of a gift.
    - Shows the full cost before a paid call starts.

    ## How to test
    1. Start a paid call from a profile.
    2. Check the price and the gift value in the sheet.
    """

    package static let aiExplanation = """
    ## What it changes
    `CallPresenter` now asks `PaymentSheet` for the price before it starts a call, and `GiftValue` holds the coins of a gift.

    ## Risky places
    - `CallPresenter.start()` waits for the payment sheet; a dismissed sheet must not start the call.

    ## Changed since my review
    `CallPresenter.swift` gained a retry when the price request fails.

    ## What to check
    - A failed price request shows an error and does not start the call.
    """
}
