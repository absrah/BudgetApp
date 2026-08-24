import SwiftUI
import SwiftData

/// The Budgets tab: a month you can page through, a summary of total
/// budgeted vs spent, and every category's status for that month.
struct BudgetListView: View {

    @Query(sort: \Category.name) private var categories: [Category]

    /// Which month is being viewed. Defaults to now; the chevrons move it.
    @State private var displayedDate: Date = .now
    @State private var editingCategory: Category?

    private var month: Int { displayedDate.month }
    private var year: Int { displayedDate.year }

    var body: some View {
        List {
            Section { monthPicker }
            Section { summary }

            Section("Categories") {
                if categories.isEmpty {
                    Text("No categories yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedCategories) { category in
                        Button {
                            editingCategory = category
                        } label: {
                            CategoryBudgetRowView(
                                category: category,
                                month: month,
                                year: year
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Budgets")
        .sheet(item: $editingCategory) { category in
            EditBudgetView(category: category, month: month, year: year)
        }
    }

    // MARK: - Month navigation

    private var monthPicker: some View {
        HStack {
            Button {
                displayedDate = displayedDate.adding(months: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(displayedDate.monthYearLabel)
                .font(.headline)

            Spacer()

            Button {
                displayedDate = displayedDate.adding(months: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            // No paging into the future — there's nothing to see there,
            // and it would imply budgets exist for months you haven't
            // reached yet.
            .disabled(isCurrentMonth)
        }
        .buttonStyle(.borderless)
    }

    private var isCurrentMonth: Bool {
        displayedDate.isSameMonth(as: .now)
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Budgeted")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(totalBudgeted.asCurrency)
                    .monospacedDigit()
            }

            HStack {
                Text("Spent")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(totalSpent.asCurrency)
                    .monospacedDigit()
            }

            Divider()

            HStack {
                Text(totalRemaining < 0 ? "Over budget" : "Remaining")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(totalRemaining.magnitude.asCurrency)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(totalRemaining < 0 ? .red : .green)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Data shaping

    /// Budgeted categories first (and the most-spent among them at the
    /// top), unbudgeted ones after — so the things you're tracking are
    /// what you see first.
    private var sortedCategories: [Category] {
        categories.sorted { a, b in
            let aHas = a.limit(forMonth: month, year: year) != nil
            let bHas = b.limit(forMonth: month, year: year) != nil
            if aHas != bHas { return aHas }
            return a.spent(forMonth: month, year: year) > b.spent(forMonth: month, year: year)
        }
    }

    private var totalBudgeted: Decimal {
        categories.reduce(Decimal(0)) {
            $0 + ($1.limit(forMonth: month, year: year) ?? 0)
        }
    }

    /// Only counts categories that actually have a budget — otherwise
    /// unbudgeted spending would make you look over budget on a total
    /// it was never part of.
    private var totalSpent: Decimal {
        categories
            .filter { $0.limit(forMonth: month, year: year) != nil }
            .reduce(Decimal(0)) { $0 + $1.spent(forMonth: month, year: year) }
    }

    private var totalRemaining: Decimal { totalBudgeted - totalSpent }
}

#Preview {
    NavigationStack {
        BudgetListView()
    }
    .modelContainer(for: [Account.self, Category.self, Budget.self, Transaction.self])
}
