import SwiftUI
import SwiftData

/// One form for both adding and editing (FIX #5). Present it with
/// `TransactionFormView()` to create, or `TransactionFormView(transaction:)`
/// to edit an existing record.
struct TransactionFormView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: TransactionFormViewModel

    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Category.name) private var categories: [Category]

    @FocusState private var amountFocused: Bool

    init() {
        _viewModel = State(initialValue: TransactionFormViewModel())
    }

    init(transaction: Transaction) {
        _viewModel = State(initialValue: TransactionFormViewModel(transaction: transaction))
    }

    var body: some View {
        NavigationStack {
            Form {
                amountSection
                detailsSection
                noteSection
            }
            .navigationTitle(viewModel.title)
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
                // Only steal focus when creating — when editing you're
                // usually here to change one specific field.
                amountFocused = !viewModel.isEditing ? true : false
            }
        }
    }

    private var amountSection: some View {
        Section {
            Picker("Type", selection: $viewModel.type) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text(viewModel.selectedAccount?.currencyCode ?? Decimal.localCurrencyCode)
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
                in: ...Date.now,
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

    private func save() {
        if viewModel.save(context: context) {
            dismiss()
        }
    }
}

#Preview {
    TransactionFormView()
        .modelContainer(for: [Account.self, Category.self, Budget.self, Transaction.self])
}
