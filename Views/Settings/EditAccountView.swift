import SwiftUI
import SwiftData

/// Creates or edits an account. Same dual-mode pattern as the transaction
/// form: no argument means create, passing one means edit.
struct EditAccountView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allAccounts: [Account]

    private let editing: Account?

    @State private var name: String = ""
    @State private var type: AccountType = .checking
    @State private var openingBalanceText: String = ""

    init() { editing = nil }
    init(account: Account) { editing = account }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)

                    Picker("Type", selection: $type) {
                        ForEach(AccountType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                }

                Section {
                    HStack {
                        Text(editing?.currencyCode ?? Decimal.localCurrencyCode)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $openingBalanceText)
                            .keyboardType(.numbersAndPunctuation)
                            .monospacedDigit()
                    }
                } header: {
                    Text("Opening balance")
                } footer: {
                    Text("What was in this account before you started tracking. The current balance is calculated from here plus every transaction.")
                }

                if let error = validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(editing == nil ? "New Account" : "Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(validationError != nil || trimmedName.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Duplicate checking now happens here, since we removed
    /// @Attribute(.unique) to keep CloudKit sync possible.
    private var validationError: String? {
        guard !trimmedName.isEmpty else { return nil }
        if Account.nameExists(trimmedName, in: allAccounts, excluding: editing) {
            return "An account with this name already exists."
        }
        return nil
    }

    private func load() {
        guard let editing else { return }
        name = editing.name
        type = editing.type
        openingBalanceText = "\(editing.openingBalance)"
    }

    private func save() {
        let balance = Decimal.parse(openingBalanceText) ?? 0

        if let editing {
            editing.name = trimmedName
            editing.type = type
            editing.openingBalance = balance
        } else {
            context.insert(
                Account(name: trimmedName, type: type, openingBalance: balance)
            )
        }
        dismiss()
    }
}
