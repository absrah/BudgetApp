import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()

    @Attribute(.unique) var name: String
    var icon: String     // SF Symbol name, e.g. "cart.fill"
    var colorHex: String // e.g. "#4A90D9"

    // The limit that auto-carries every month until you change it.
    // Optional — a category doesn't have to be budgeted.
    var defaultMonthlyLimit: Decimal?

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []

    // Sparse per-month overrides. Most months have none, and the
    // default above is used instead. One only exists if you manually
    // edited that specific month.
    @Relationship(deleteRule: .cascade, inverse: \Budget.category)
    var budgetOverrides: [Budget] = []

    init(
        name: String,
        icon: String = "tag.fill",
        colorHex: String = "#4A90D9",
        defaultMonthlyLimit: Decimal? = nil
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.defaultMonthlyLimit = defaultMonthlyLimit
    }

    // MARK: - Budget logic

    /// Override for that month if one exists, otherwise the auto-carrying default.
    func limit(forMonth month: Int, year: Int) -> Decimal? {
        if let override = budgetOverrides.first(where: { $0.month == month && $0.year == year }) {
            return override.monthlyLimit
        }
        return defaultMonthlyLimit
    }

    /// Total spent in this category for a given month.
    func spent(forMonth month: Int, year: Int) -> Decimal {
        transactions
            .filter { $0.type == .expense && $0.isIn(month: month, year: year) }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    /// How much of the budget is used, 0.0–1.0+ (can exceed 1 if overspent).
    /// Returns nil when no budget is set, so the UI can hide the progress bar.
    func progress(forMonth month: Int, year: Int) -> Double? {
        guard let limit = limit(forMonth: month, year: year), limit > 0 else { return nil }
        let ratio = spent(forMonth: month, year: year) / limit
        return NSDecimalNumber(decimal: ratio).doubleValue
    }

    /// Remaining budget — negative means overspent.
    func remaining(forMonth month: Int, year: Int) -> Decimal? {
        guard let limit = limit(forMonth: month, year: year) else { return nil }
        return limit - spent(forMonth: month, year: year)
    }
}

// Small helper so the date-filtering logic lives in one place instead of
// being re-written in every view that needs it.
extension Transaction {
    func isIn(month: Int, year: Int) -> Bool {
        let comps = Calendar.current.dateComponents([.month, .year], from: date)
        return comps.month == month && comps.year == year
    }
}