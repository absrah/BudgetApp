import SwiftUI
import SwiftData
import Charts

/// The Reports tab: headline totals, a donut of spending by category, and
/// an income-vs-expense trend over the selected range.
struct ReportsView: View {

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    @State private var viewModel = ReportsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                rangePicker

                if transactions.isEmpty {
                    ContentUnavailableView(
                        "Nothing to report yet",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Log a few transactions and your spending patterns will show up here.")
                    )
                    .padding(.top, 60)
                } else {
                    summaryCards
                    categoryChart
                    trendChart
                    categoryList
                }
            }
            .padding()
        }
        .navigationTitle("Reports")
    }

    // MARK: - Range

    private var rangePicker: some View {
        Picker("Range", selection: $viewModel.range) {
            ForEach(ReportsViewModel.DateRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary

    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "Spent",
                value: viewModel.totalSpent(transactions),
                color: .red
            )
            summaryCard(
                title: "Income",
                value: viewModel.totalIncome(transactions),
                color: .green
            )
            summaryCard(
                title: "Avg/month",
                value: viewModel.averageMonthlySpend(transactions),
                color: .blue
            )
        }
    }

    private func summaryCard(title: String, value: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.asCurrencyRounded)
                .font(.headline)
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Category donut

    private var categoryChart: some View {
        let data = viewModel.categoryBreakdown(transactions)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Where your money went")
                .font(.headline)

            if data.isEmpty {
                Text("No expenses in this period.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                // SectorMark is the donut/pie mark, iOS 17+.
                // innerRadius leaves the hole in the middle.
                Chart(data) { slice in
                    SectorMark(
                        angle: .value("Amount", slice.amount.asDouble),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(slice.color)
                    .cornerRadius(4)
                }
                .frame(height: 220)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Monthly trend

    private var trendChart: some View {
        let data = viewModel.monthlyTotals(transactions)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Income vs spending")
                .font(.headline)

            Chart(data) { month in
                // Two bars per month, side by side, via .position.
                BarMark(
                    x: .value("Month", month.date, unit: .month),
                    y: .value("Amount", month.expense.asDouble)
                )
                .foregroundStyle(.red.opacity(0.8))
                .position(by: .value("Type", "Spent"))

                BarMark(
                    x: .value("Month", month.date, unit: .month),
                    y: .value("Amount", month.income.asDouble)
                )
                .foregroundStyle(.green.opacity(0.8))
                .position(by: .value("Type", "Income"))
            }
            .chartForegroundStyleScale([
                "Spent": Color.red.opacity(0.8),
                "Income": Color.green.opacity(0.8)
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
            .frame(height: 200)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Ranked list
    // The donut shows proportions well but exact figures poorly, so the
    // numbers live here underneath it.

    private var categoryList: some View {
        let data = viewModel.categoryBreakdown(transactions)

        return VStack(alignment: .leading, spacing: 12) {
            if !data.isEmpty {
                Text("Breakdown")
                    .font(.headline)

                ForEach(data) { slice in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 10, height: 10)

                        Text(slice.name)
                            .font(.subheadline)

                        Spacer()

                        Text(slice.share.formatted(.percent.precision(.fractionLength(0))))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()

                        Text(slice.amount.asCurrency)
                            .font(.subheadline.weight(.medium))
                            .monospacedDigit()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        ReportsView()
    }
    .modelContainer(for: [Account.self, Category.self, Budget.self, Transaction.self])
}
