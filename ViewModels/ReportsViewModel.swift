import Foundation
import SwiftUI

/// Shapes raw transactions into chart-ready data. This screen keeps a
/// ViewModel because there IS real logic here — grouping, summing,
/// ranking — unlike the list screens which just display what @Query hands
/// them.
///
/// The transactions are passed IN rather than queried here, so this class
/// stays free of SwiftData and its logic is testable in isolation.
@Observable
final class ReportsViewModel {

    var range: DateRange = .last6Months

    enum DateRange: String, CaseIterable, Identifiable {
        case thisMonth = "This Month"
        case last3Months = "3 Months"
        case last6Months = "6 Months"
        case thisYear = "This Year"

        var id: String { rawValue }

        /// How many whole months back the range starts, counting the
        /// current month as one.
        var monthsBack: Int {
            switch self {
            case .thisMonth:    1
            case .last3Months:  3
            case .last6Months:  6
            case .thisYear:     Date.now.month
            }
        }
    }

    // MARK: - Chart data types

    /// One slice of the category breakdown.
    struct CategorySpend: Identifiable {
        let id: UUID
        let name: String
        let colorHex: String
        let amount: Decimal
        let share: Double   // 0–1, portion of total spending

        var color: Color { Color(hex: colorHex) }
    }

    /// One bar in the monthly trend.
    struct MonthlyTotal: Identifiable {
        let id: String      // "2026-08"
        let date: Date      // first of that month, for the chart axis
        let income: Decimal
        let expense: Decimal

        var net: Decimal { income - expense }
    }

    // MARK: - Filtering

    /// Transactions falling inside the selected range.
    func inRange(_ transactions: [Transaction]) -> [Transaction] {
        let start = Date.now
            .adding(months: -(range.monthsBack - 1))
            .startOfMonth
        return transactions.filter { $0.date >= start }
    }

    // MARK: - Aggregation

    /// Expenses grouped by category, largest first. Uncategorised
    /// spending is folded into a single "Uncategorised" entry rather than
    /// being dropped, so the totals still reconcile.
    func categoryBreakdown(_ transactions: [Transaction]) -> [CategorySpend] {
        let expenses = inRange(transactions).filter { $0.type == .expense }
        let total = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        guard total > 0 else { return [] }

        let grouped = Dictionary(grouping: expenses) { $0.category?.id }

        return grouped.compactMap { categoryID, items -> CategorySpend? in
            let amount = items.reduce(Decimal(0)) { $0 + $1.amount }
            guard amount > 0 else { return nil }

            let category = items.first?.category
            return CategorySpend(
                id: categoryID ?? UUID(),
                name: category?.name ?? "Uncategorised",
                colorHex: category?.colorHex ?? "#8E8E93",
                amount: amount,
                share: (amount / total).asDouble
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    /// Income and expense totals per month, oldest first so the chart
    /// reads left to right chronologically. Months with no activity are
    /// included as zeros — otherwise the trend line would skip gaps and
    /// imply continuity that isn't there.
    func monthlyTotals(_ transactions: [Transaction]) -> [MonthlyTotal] {
        let scoped = inRange(transactions)

        let months: [Date] = (0..<range.monthsBack)
            .map { Date.now.adding(months: -$0).startOfMonth }
            .reversed()

        return months.map { monthStart in
            let items = scoped.filter {
                $0.date >= monthStart && $0.date < monthStart.startOfNextMonth
            }
            return MonthlyTotal(
                id: String(format: "%04d-%02d", monthStart.year, monthStart.month),
                date: monthStart,
                income: items.filter { $0.type == .income }
                    .reduce(Decimal(0)) { $0 + $1.amount },
                expense: items.filter { $0.type == .expense }
                    .reduce(Decimal(0)) { $0 + $1.amount }
            )
        }
    }

    // MARK: - Headline figures

    func totalSpent(_ transactions: [Transaction]) -> Decimal {
        inRange(transactions)
            .filter { $0.type == .expense }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    func totalIncome(_ transactions: [Transaction]) -> Decimal {
        inRange(transactions)
            .filter { $0.type == .income }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    /// Average monthly spend across the range — useful for sanity-checking
    /// whether your budgets are set anywhere near reality.
    func averageMonthlySpend(_ transactions: [Transaction]) -> Decimal {
        let months = Decimal(max(range.monthsBack, 1))
        return totalSpent(transactions) / months
    }
}
