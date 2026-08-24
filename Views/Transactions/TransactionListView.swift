import SwiftUI
import SwiftData

struct TransactionListView: View {

    // @Query fetches from SwiftData AND auto-refreshes the UI whenever
    // the data changes. This is why this screen has no ViewModel —
    // routing through one would mean giving up that automatic behavior
    // and manually re-fetching instead.
    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    // The context is how you insert/delete. Injected by .modelContainer
    // up in the app entry point.
    @Environment(\.modelContext) private var context

    @State private var showingAddSheet = false
    /// FIX #5: tapping a row opens the same form in edit mode.
    @State private var editingTransaction: Transaction?
    @State private var searchText = ""

    var body: some View {
        Group {
            if transactions.isEmpty {
                emptyState
            } else {
                transactionList
            }
        }
        .navigationTitle("Transactions")
        .searchable(text: $searchText, prompt: "Search notes or categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            TransactionFormView()
        }
        // item-based sheet: presents whenever editingTransaction is set,
        // and hands the form the record that was tapped.
        .sheet(item: $editingTransaction) { transaction in
            TransactionFormView(transaction: transaction)
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Transactions", systemImage: "tray")
        } description: {
            Text("Tap + to log your first transaction.")
        }
    }

    private var transactionList: some View {
        List {
            // Section per month, newest first.
            ForEach(groupedByMonth, id: \.key) { group in
                Section {
                    ForEach(group.transactions) { transaction in
                        Button {
                            editingTransaction = transaction
                        } label: {
                            TransactionRowView(transaction: transaction)
                        }
                        // keeps the row looking like a row, not a blue link
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        delete(at: offsets, in: group.transactions)
                    }
                } header: {
                    HStack {
                        Text(group.label)
                        Spacer()
                        // Running net total for that month.
                        Text(group.net.asSignedCurrency)
                            .monospacedDigit()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Data shaping

    /// Filtered by the search field, if anything's typed.
    private var filtered: [Transaction] {
        guard !searchText.isEmpty else { return transactions }
        return transactions.filter {
            $0.note.localizedCaseInsensitiveContains(searchText)
            || ($0.category?.name.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private struct MonthGroup {
        let key: String       // stable id like "2026-08"
        let label: String     // display like "August 2026"
        let transactions: [Transaction]
        let net: Decimal
    }

    /// Groups transactions into month sections. Done in Swift rather than
    /// in the @Query predicate because SwiftData can't group natively.
    private var groupedByMonth: [MonthGroup] {
        let groups = Dictionary(grouping: filtered) { transaction in
            String(format: "%04d-%02d", transaction.date.year, transaction.date.month)
        }

        return groups
            .map { key, items in
                MonthGroup(
                    key: key,
                    label: items.first?.date.monthYearLabel ?? key,
                    transactions: items,
                    net: items.reduce(Decimal(0)) { $0 + $1.signedAmount }
                )
            }
            .sorted { $0.key > $1.key } // newest month first
    }

    // MARK: - Actions

    /// Deletes by looking up the actual object from the group, not by
    /// raw index into the full array — indexes don't line up once the
    /// list is filtered and grouped.
    private func delete(at offsets: IndexSet, in group: [Transaction]) {
        for index in offsets {
            context.delete(group[index])
        }
    }
}

#Preview {
    NavigationStack {
        TransactionListView()
    }
    .modelContainer(for: [Account.self, Category.self, Budget.self, Transaction.self])
}