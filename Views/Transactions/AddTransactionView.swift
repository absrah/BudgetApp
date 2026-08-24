import SwiftUI
import SwiftData

struct AddTransactionView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // The ViewModel is owned by this view and lives as long as it does.
    // @State is correct for @Observable classes in iOS 17+ (you no
    // longer use @StateObject for these).
    @State private var viewModel = AddTransactionViewModel()

    // Pickers need the available options, so this view queries them.
    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Category.name) private var categories: [Category]

    // Puts the keyboard straight into the amount field on open —
    // small thing, but it's the field you always fill first.
    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                amountSection
                detailsSection
                noteSection
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!viewModel.isValid)
                }
            }
            .onAppear {
                viewModel.applyDefaults(accounts: accounts, categories: categories)
                amountFocused = true
            }
        }
    }

    // MARK: - Sections

    private var amountSection: some View {
        Section {
            // Expense/Income toggle up top, since it changes what the
            // amount means.
            Picker("Type", selection: $viewModel.type) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text(Decimal.localCurrencyCode)
                    .foregroundStyle(.secondary)

                TextField("0.00", text: $viewModel.amountText)
                    .keyboardType(.decimalPad)
                    .font(.title2.weight(.medium))
                    .monospacedDigit()
                    .focused($amountFocused)
            }

            if let error = viewModel.amountError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var detailsSection: some View {
        Section {
            if accounts.isEmpty {
                // Guard rail: you can't save without an account, so say
                // so plainly rather than showing an empty picker.
                Label("Add an account in Settings first", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.callout)
            } else {
                Picker("Account", selection: $viewModel.selectedAccount) {
                    ForEach(accounts) { account in
                        Label(account.name, systemImage: account.type.icon)
                            .tag(Optional(account))
                    }
                }
            }

            Picker("Category", selection: $viewModel.selectedCategory) {
                Text("None").tag(Optional<Category>.none)
                ForEach(categories) { category in
                    Label(category.name, systemImage: category.icon)
                        .tag(Optional(category))
                }
            }

            DatePicker(
                "Date",
                selection: $viewModel.date,
                in: ...Date.now,          // no future-dating transactions
                displayedComponents: .date
            )
        }
    }

    private var noteSection: some View {
        Section {
            TextField("Note (optional)", text: $viewModel.note, axis: .vertical)
                .lineLimit(1...3)
        }
    }

    // MARK: - Actions

    private func save() {
        // Only dismiss if the save actually succeeded — otherwise the
        // sheet would close and silently lose the entry.
        if viewModel.save(context: context) {
            dismiss()
        }
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: [Account.self, Category.self, Budget.self, Transaction.self])
}
