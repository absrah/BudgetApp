import Foundation
import SwiftData

/// FIX #5: this replaces AddTransactionViewModel and now handles BOTH
/// creating and editing. Previously you could only add or delete, so
/// fixing a typo meant deleting the record and re-entering it — which
/// also destroyed the original timestamp.
///
/// One form for both paths means validation and parsing logic can't
/// drift apart between "add" and "edit".
@Observable
final class TransactionFormViewModel {

    /// nil = creating a new transaction. Non-nil = editing that one.
    private let editing: Transaction?

    var amountText: String = ""
    var note: String = ""
    var date: Date = .now
    var type: TransactionType = .expense
    var selectedCategory: Category?
    var selectedAccount: Account?

    var isEditing: Bool { editing != nil }
    var title: String { isEditing ? "Edit Transaction" : "New Transaction" }

    /// Creating.
    init() {
        self.editing = nil
    }

    /// Editing — fields are pre-filled from the existing record.
    init(transaction: Transaction) {
        self.editing = transaction
        self.amountText = "\(transaction.amount)"
        self.note = transaction.note
        self.date = transaction.date
        self.type = transaction.type
        self.selectedCategory = transaction.category
        self.selectedAccount = transaction.account
    }

    // MARK: - Validation

    var parsedAmount: Decimal? {
        guard let value = Decimal.parse(amountText), value > 0 else { return nil }
        return value
    }

    var isValid: Bool {
        parsedAmount != nil && selectedAccount != nil
    }

    var amountError: String? {
        guard !amountText.isEmpty else { return nil }
        guard let value = Decimal.parse(amountText) else { return "Enter a valid number." }
        guard value > 0 else { return "Amount must be greater than zero." }
        return nil
    }

    // MARK: - Saving

    /// Updates the existing record, or inserts a new one.
    /// Returns false if validation failed, so the view knows not to dismiss.
    @discardableResult
    func save(context: ModelContext) -> Bool {
        guard let amount = parsedAmount, let account = selectedAccount else { return false }
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = editing {
            // Mutating a @Model object is enough — SwiftData tracks the
            // change and the @Query-driven list refreshes itself.
            existing.amount = amount
            existing.date = date
            existing.note = cleanNote
            existing.type = type
            existing.category = selectedCategory
            existing.account = account
            // currencyCode deliberately NOT changed: the currency the
            // money was actually spent in doesn't change because you
            // corrected a typo.
        } else {
            let transaction = Transaction(
                amount: amount,
                date: date,
                note: cleanNote,
                type: type,
                category: selectedCategory,
                account: account
            )
            context.insert(transaction)
        }

        return true
    }

    func applyDefaults(accounts: [Account], categories: [Category]) {
        guard !isEditing else { return } // never override real values
        if selectedAccount == nil {
            selectedAccount = accounts.first { !$0.isArchived } ?? accounts.first
        }
        if selectedCategory == nil {
            selectedCategory = categories.first
        }
    }
}
