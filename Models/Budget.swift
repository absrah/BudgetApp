import Foundation
import SwiftData

/// A ONE-OFF manual override of a category's budget for one specific month.
/// Not created automatically each month — only when you explicitly change
/// that month's limit. Otherwise `Category.defaultMonthlyLimit` applies.
@Model
final class Budget {
    var id: UUID = UUID()

    var monthlyLimit: Decimal
    var month: Int  // 1-12
    var year: Int

    // Back-reference. Not marked @Relationship because Category already
    // declares the inverse — SwiftData only needs it stated once.
    var category: Category?

    init(monthlyLimit: Decimal, month: Int, year: Int) {
        self.monthlyLimit = monthlyLimit
        self.month = month
        self.year = year
    }

    /// Convenience initializer for "override the current month".
    convenience init(monthlyLimit: Decimal, date: Date = .now) {
        let comps = Calendar.current.dateComponents([.month, .year], from: date)
        self.init(
            monthlyLimit: monthlyLimit,
            month: comps.month ?? 1,
            year: comps.year ?? 2026
        )
    }
}