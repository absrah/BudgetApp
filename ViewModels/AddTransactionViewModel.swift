import Foundation
import SwiftData

/// Holds the form's state and the logic for validating and saving it.
/// This screen keeps a ViewModel (unlike the list) because there's real
/// work here: parsing a String into Decimal, validating, and building
/// the object. The list screen had none of that.
///
/// @Observable is the iOS 17+ replacement for ObservableObject —
/// less boilerplate, no @Published needed on each property.
@Observable
final class AddTransactionViewModel {

    // MARK: - Form fields

    var amountText: String = ""
    var note: String = ""
    var date: Date = .now
    var type: TransactionType = .expense
    var selectedCategory: Category?
    var selectedAccount: Account?

    // MARK: - Validation

    /// The parsed amount, or nil if what's typed isn't a valid number.
    /// Uses the parser from Decimal+Formatting so "1,200" and "RM 50"
    /// both work.
    var parsedAmount: Decimal? {
        guard let value = Decimal.parse(amountText), value > 0 else { return nil }
        return value
    }

    /// Drives whether the Save button is enabled.
    var isValid: Bool {
        parsedAmount != nil && selectedAccount != nil
    }

    /// Shown under the amount field once the user has typed something
    /// invalid. Stays nil while the field is empty so a fresh form
    /// doesn't greet you with an error.
    var amountError: String? {
        guard !amountText.isEmpty else { return nil }
        guard let value = Decimal.parse(amountText) else {
            return "Enter a valid number."
        }
        guard value > 0 else {
            return "Amount must be greater than zero."
        }
        return nil
    }

    // MARK: - Saving

    /// Builds the Transaction and inserts it into SwiftData.
    /// Returns false if validation fails, so the view knows not to dismiss.
    ///
    /// The context is passed in rather than stored on the ViewModel —
    /// the view owns it via @Environment, and passing it keeps this
    /// class free of SwiftUI dependencies.
    @discardableResult
    func save(context: ModelContext) -> Bool {
        guard let amount = parsedAmount, let account = selectedAccount else {
            return false
        }

        let transaction = Transaction(
            amount: amount,
            date: date,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            category: selectedCategory,
            account: account
        )

        context.insert(transaction)
        return true
    }

    /// Picks sensible starting values when the form opens, so you're not
    /// forced to tap through pickers for the common case.
    func applyDefaults(accounts: [Account], categories: [Category]) {
        if selectedAccount == nil {
            selectedAccount = accounts.first { !$0.isArchived } ?? accounts.first
        }
        if selectedCategory == nil {
            selectedCategory = categories.first
        }
    }
}
