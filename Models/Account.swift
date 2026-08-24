import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID = UUID()

    // .unique stops you accidentally creating two accounts with the
    // same name. NOTE: if you later add CloudKit sync, unique
    // constraints aren't supported there — you'd remove this then.
    @Attribute(.unique) var name: String

    var type: AccountType

    // IMPORTANT: money is stored as `Decimal`, never `Double`.
    // Double is binary floating point, so 0.1 + 0.2 != 0.3 exactly.
    // Those tiny errors accumulate across hundreds of transactions and
    // your balances drift by cents. Decimal does exact base-10 math,
    // which is what currency needs.
    var openingBalance: Decimal

    var isArchived: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction] = []

    init(name: String, type: AccountType, openingBalance: Decimal = 0) {
        self.name = name
        self.type = type
        self.openingBalance = openingBalance
    }

    // Balance is COMPUTED, not stored. Storing it would mean updating it
    // on every add/edit/delete, and any missed update silently corrupts
    // your data with no way to detect it. Deriving it from the
    // transactions means it can never disagree with them.
    var currentBalance: Decimal {
        transactions.reduce(openingBalance) { $0 + $1.signedAmount }
    }

    var formattedBalance: String {
        currentBalance.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case checking = "Checking"
    case savings = "Savings"
    case credit = "Credit Card"
    case cash = "Cash"

    // Identifiable lets you use this directly in a SwiftUI ForEach/Picker
    // without writing `id: \.self` every time.
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