import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID = UUID()

    var amount: Decimal
    var date: Date
    var note: String
    var type: TransactionType

    // FIX #2: the currency is captured AT ENTRY TIME and stored with the
    // record. Previously we formatted using Locale.current at display
    // time, which meant changing your phone's region would silently
    // relabel every past transaction — a RM50 coffee from last year
    // would start reading as $50. Money records must remember their own
    // currency; it is part of the fact, not a display preference.
    var currencyCode: String

    var category: Category?
    var account: Account?

    init(
        amount: Decimal,
        date: Date = .now,
        note: String = "",
        type: TransactionType,
        category: Category? = nil,
        account: Account? = nil,
        currencyCode: String? = nil
    ) {
        self.amount = amount
        self.date = date
        self.note = note
        self.type = type
        self.category = category
        self.account = account
        // Inherit the account's currency when there is one, otherwise
        // fall back to the phone's current region.
        self.currencyCode = currencyCode
            ?? account?.currencyCode
            ?? Decimal.localCurrencyCode
    }

    /// `amount` is always stored positive; direction comes from `type`.
    var signedAmount: Decimal {
        type == .expense ? -amount : amount
    }

    /// Formatted in the currency this transaction was RECORDED in.
    var formattedAmount: String {
        amount.asCurrency(code: currencyCode)
    }

    var formattedSignedAmount: String {
        signedAmount.asSignedCurrency(code: currencyCode)
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "Income"
    case expense = "Expense"
}