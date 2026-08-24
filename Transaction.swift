import Foundation
import SwiftData

@Model
final class Transaction {
    var amount: Double
    var date: Date
    var note: String
    var type: TransactionType

    // Links to the other models. Both optional so a transaction
    // can technically exist even if, say, its category gets removed.
    var category: Category?
    var account: Account?

    init(
        amount: Double,
        date: Date = .now,
        note: String = "",
        type: TransactionType,
        category: Category? = nil,
        account: Account? = nil
    ) {
        self.amount = amount
        self.date = date
        self.note = note
        self.type = type
        self.category = category
        self.account = account
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "Income"
    case expense = "Expense"
}
