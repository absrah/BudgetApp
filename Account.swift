import Foundation
import SwiftData

// @Model turns a normal Swift class into something SwiftData can save,
// query, and update automatically — this replaces what a database table
// + ORM would normally do for you in a backend setup.
@Model
final class Account {
    var name: String
    var type: AccountType
    var balance: Double

    // A relationship: one Account can have many Transactions.
    // deleteRule: .cascade means if you delete an Account, its
    // Transactions get deleted too (makes sense — a transaction
    // can't exist without the account it happened on).
    // inverse tells SwiftData this links to `account` on the Transaction side.
    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction] = []

    init(name: String, type: AccountType, balance: Double = 0) {
        self.name = name
        self.type = type
        self.balance = balance
    }
}

// A plain enum for account types. CaseIterable lets you loop over
// all cases automatically — useful for populating a picker in the UI.
enum AccountType: String, Codable, CaseIterable {
    case checking = "Checking"
    case savings = "Savings"
    case credit = "Credit Card"
    case cash = "Cash"
}
