import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()

    @Attribute(.unique) var name: String
    var icon: String
    var colorHex: String

    /// The limit that auto-carries forward every month until changed.
    /// Never set this directly from the UI — call `changeDefaultLimit`
    /// instead, so past months get frozen first (see FIX #1).
    var defaultMonthlyLimit: Decimal?

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []

    /// Per-month overrides. Created either when you manually edit one
    /// month, or automatically to freeze history when the default changes.
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

    // MARK: - Reading the budget

    /// Override for that month if one exists, otherwise the auto-carrying default.
    func limit(forMonth month: Int, year: Int) -> Decimal? {
        if let override = budgetOverrides.first(where: { $0.month == month && $0.year == year }) {
            return override.monthlyLimit
        }
        return defaultMonthlyLimit
    }

    func spent(forMonth month: Int, year: Int) -> Decimal {
        transactions
            .filter { $0.type == .expense && $0.isIn(month: month, year: year) }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    /// 0.0–1.0+, or nil when no budget is set so the UI can hide the bar.
    func progress(forMonth month: Int, year: Int) -> Double? {
        guard let limit = limit(forMonth: month, year: year), limit > 0 else { return nil }
        return (spent(forMonth: month, year: year) / limit).asDouble
    }

    /// Negative means overspent.
    func remaining(forMonth month: Int, year: Int) -> Decimal? {
        guard let limit = limit(forMonth: month, year: year) else { return nil }
        return limit - spent(forMonth: month, year: year)
    }

    // MARK: - Changing the budget

    /// FIX #1: changing the default used to silently REWRITE HISTORY.
    /// Because months without an override fall back to the current
    /// default, raising Groceries from 400 to 600 in August made every
    /// past month retroactively claim a 600 limit — so old reports would
    /// show months as "under budget" that were actually overspent.
    ///
    /// This freezes the past first: every month that already has
    /// transactions (up to and including the current one) gets an
    /// explicit override recording the OLD limit. Only then does the new
    /// default take effect, applying from next month onward.
    func changeDefaultLimit(to newLimit: Decimal?, context: ModelContext, asOf date: Date = .now) {
        if let oldLimit = defaultMonthlyLimit {
            for (month, year) in historicalMonths(upTo: date) {
                let alreadyOverridden = budgetOverrides.contains {
                    $0.month == month && $0.year == year
                }
                guard !alreadyOverridden else { continue }

                let frozen = Budget(monthlyLimit: oldLimit, month: month, year: year)
                frozen.category = self
                context.insert(frozen)
                budgetOverrides.append(frozen)
            }
        }

        defaultMonthlyLimit = newLimit
    }

    /// Sets or replaces the override for one specific month, leaving the
    /// auto-carrying default untouched. This is the "manual adjustment"
    /// path — adjusting one month doesn't change your ongoing budget.
    func setOverride(_ limit: Decimal, forMonth month: Int, year: Int, context: ModelContext) {
        if let existing = budgetOverrides.first(where: { $0.month == month && $0.year == year }) {
            existing.monthlyLimit = limit
        } else {
            let override = Budget(monthlyLimit: limit, month: month, year: year)
            override.category = self
            context.insert(override)
            budgetOverrides.append(override)
        }
    }

    /// Removes a month's override so it falls back to the default again.
    func clearOverride(forMonth month: Int, year: Int, context: ModelContext) {
        guard let existing = budgetOverrides.first(where: { $0.month == month && $0.year == year })
        else { return }
        budgetOverrides.removeAll { $0.id == existing.id }
        context.delete(existing)
    }

    /// Distinct months that actually have transactions, up to `date`.
    /// Bounded by real data, so this never loops over empty years.
    private func historicalMonths(upTo date: Date) -> [(month: Int, year: Int)] {
        let cutoff = (year: date.year, month: date.month)

        let months = Set(transactions.compactMap { transaction -> String? in
            let m = transaction.date.month
            let y = transaction.date.year
            guard (y, m) <= (cutoff.year, cutoff.month) else { return nil }
            return String(format: "%04d-%02d", y, m)
        })

        return months.compactMap { key in
            let parts = key.split(separator: "-")
            guard parts.count == 2,
                  let y = Int(parts[0]),
                  let m = Int(parts[1]) else { return nil }
            return (month: m, year: y)
        }
    }
}

// Small helper so date filtering lives in one place.
extension Transaction {
    func isIn(month: Int, year: Int) -> Bool {
        let comps = Calendar.current.dateComponents([.month, .year], from: date)
        return comps.month == month && comps.year == year
    }
}