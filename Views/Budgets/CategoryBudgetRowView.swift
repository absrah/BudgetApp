import SwiftUI

/// One category's budget status for a given month: icon, name, spend
/// against limit, and a progress bar.
struct CategoryBudgetRowView: View {
    let category: Category
    let month: Int
    let year: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: category.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(category.name)
                        .font(.body)

                    // Marks months you've manually adjusted, so an unusual
                    // limit doesn't look like a bug when you revisit it.
                    if hasOverride {
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(spent.asCurrency)
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                }

                if let limit, limit > 0 {
                    ProgressView(value: min(progress ?? 0, 1))
                        .tint(barColor)

                    HStack {
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(isOverspent ? .red : .secondary)
                        Spacer()
                        Text("of \(limit.asCurrencyRounded)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } else {
                    Text("No budget set")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Derived values
    // All of this comes from the model — the view does no budget math
    // itself, which is why Category owns those helpers.

    private var limit: Decimal? { category.limit(forMonth: month, year: year) }
    private var spent: Decimal { category.spent(forMonth: month, year: year) }
    private var progress: Double? { category.progress(forMonth: month, year: year) }
    private var remaining: Decimal? { category.remaining(forMonth: month, year: year) }

    private var hasOverride: Bool {
        category.budgetOverrides.contains { $0.month == month && $0.year == year }
    }

    private var isOverspent: Bool {
        guard let remaining else { return false }
        return remaining < 0
    }

    private var statusText: String {
        guard let remaining else { return "" }
        return isOverspent
            ? "\(remaining.magnitude.asCurrency) over"
            : "\(remaining.asCurrency) left"
    }

    /// Green while comfortable, amber past 80%, red once over.
    private var barColor: Color {
        guard let progress else { return .gray }
        if progress >= 1.0 { return .red }
        if progress >= 0.8 { return .orange }
        return .green
    }

    private var color: Color { Color(hex: category.colorHex) }
}
