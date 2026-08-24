import Foundation
import SwiftData

@Model
final class Budget {
    var monthlyLimit: Double
    var month: Int  // 1-12
    var year: Int   // e.g. 2026

    // Back-reference to the category this budget belongs to.
    // Not marked with @Relationship here because Category already
    // owns the relationship above (SwiftData only needs it declared once).
    var category: Category?

    init(monthlyLimit: Double, month: Int, year: Int) {
        self.monthlyLimit = monthlyLimit
        self.month = month
        self.year = year
    }
}
