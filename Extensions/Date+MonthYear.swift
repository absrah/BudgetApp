import Foundation

extension Date {

    /// The month number (1-12) for this date.
    var month: Int {
        Calendar.current.component(.month, from: self)
    }

    /// The year for this date.
    var year: Int {
        Calendar.current.component(.year, from: self)
    }

    /// Midnight on the 1st of this date's month.
    /// Used as the lower bound when filtering transactions by month.
    var startOfMonth: Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: comps) ?? self
    }

    /// The very start of the NEXT month — used as an exclusive upper
    /// bound. Comparing `date >= start && date < end` avoids the classic
    /// bug of missing transactions logged late on the last day.
    var startOfNextMonth: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth) ?? self
    }

    /// Midnight today — for "today's spending" style filters.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// "August 2026" — for the month header in lists and reports.
    var monthYearLabel: String {
        formatted(.dateTime.month(.wide).year())
    }

    /// "24 Aug" — compact form for transaction rows.
    var shortDayLabel: String {
        formatted(.dateTime.day().month(.abbreviated))
    }

    /// True if this date falls in the same month and year as another.
    func isSameMonth(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .month)
    }

    /// Steps back or forward by whole months. Used by the month picker
    /// in the budgets and reports tabs.
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
}
