import Foundation
import SwiftData

@Model
final class Transaction {
    // Stable identity, independent of SwiftData's internal object ID.
    // Useful later for CSV export/import and for notification identifiers.
    var id: UUID = UUID()

    // Decimal, not Double — see note in Account.swift. This is the single
    // most important change for a money app.
    var amount: Decimal
    var date: Date
    var note: String
    var type: TransactionType

    var category: Category?
    var account: Account?

    init(
        amount: Decimal,
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

    // `amount` is always stored positive; direction comes from `type`.
    // This keeps entry simple (you never type a minus sign) while still
    // letting you sum a mixed list correctly.
    var signedAmount: Decimal {
        type == .expense ? -amount : amount
    }

    // Formats using whatever region the phone is set to, so no
    // hardcoded currency symbol anywhere in the app.
    var formattedAmount: String {
        amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "Income"
    case expense = "Expense"
}