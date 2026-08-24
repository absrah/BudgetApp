import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID = UUID()

    // FIX #4: no @Attribute(.unique) here.
    // CloudKit does not support unique constraints, and adding sync
    // later would mean removing this and de-duplicating by hand.
    // Uniqueness is enforced in the UI instead (see nameExists below).
    var name: String
    var type: AccountType

    /// Money is Decimal, never Double — exact base-10 arithmetic.
    var openingBalance: Decimal

    /// FIX #2: an account is denominated in a currency. New transactions
    /// on this account inherit it, so records stay correct even if you
    /// later change your phone's region or add a foreign account.
    var currencyCode: String

    /// Prefer archiving over deleting — see the delete rule note below.
    var isArchived: Bool = false

    // FIX #3: changed from .cascade to .nullify.
    // Previously, deleting an account silently destroyed every
    // transaction that ever happened on it — an irreversible loss of
    // financial history from one tap. Now the transactions survive with
    // no account attached, so the record is preserved and the mistake is
    // recoverable. Archiving remains the intended way to retire an
    // account you no longer use.
    @Relationship(deleteRule: .nullify, inverse: \Transaction.account)
    var transactions: [Transaction] = []

    init(
        name: String,
        type: AccountType,
        openingBalance: Decimal = 0,
        currencyCode: String? = nil
    ) {
        self.name = name
        self.type = type
        self.openingBalance = openingBalance
        self.currencyCode = currencyCode ?? Decimal.localCurrencyCode
    }

    /// Computed, never stored — it can't drift out of sync with the
    /// transactions it's derived from.
    var currentBalance: Decimal {
        transactions.reduce(openingBalance) { $0 + $1.signedAmount }
    }

    /// Case-insensitive duplicate check, replacing the removed
    /// @Attribute(.unique). Call before inserting a new account.
    static func nameExists(_ name: String, in accounts: [Account], excluding: Account? = nil) -> Bool {
        let target = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return accounts.contains {
            $0.id != excluding?.id && $0.name.lowercased() == target
        }
    }

    var formattedBalance: String {
        currentBalance.asCurrency(code: currencyCode)
    }
}

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case checking = "Checking"
    case savings = "Savings"
    case credit = "Credit Card"
    case cash = "Cash"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .checking: "banknote.fill"
        case .savings:  "building.columns.fill"
        case .credit:   "creditcard.fill"
        case .cash:     "wallet.bifold.fill"
        }
    }
}