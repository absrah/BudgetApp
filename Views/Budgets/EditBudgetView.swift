import SwiftUI
import SwiftData

/// Editing a category's budget, with the two paths kept clearly separate:
///
///  - Ongoing limit  → changes the auto-carrying default from now on,
///                     and freezes past months at the old value.
///  - This month only → a one-off override; the ongoing limit is untouched.
///
/// Conflating these is what caused the retroactive-rewrite bug, so the
/// UI names them explicitly rather than showing one ambiguous field.
struct EditBudgetView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let category: Category
    let month: Int
    let year: Int

    @State private var defaultText: String = ""
    @State private var overrideText: String = ""
    @State private var showingRemoveConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                spentSection
                ongoingSection
                thisMonthSection
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear(perform: loadCurrentValues)
        }
    }

    // MARK: - Sections

    private var spentSection: some View {
        Section {
            LabeledContent("Spent this month") {
                Text(category.spent(forMonth: month, year: year).asCurrency)
                    .monospacedDigit()
            }
        }
    }

    private var ongoingSection: some View {
        Section {
            HStack {
                Text(Decimal.localCurrencyCode)
                    .foregroundStyle(.secondary)
                TextField("No limit", text: $defaultText)
                    .keyboardType(.decimalPad)
                    .monospacedDigit()
            }
        } header: {
            Text("Ongoing monthly limit")
        } footer: {
            Text("Applies every month from now on. Past months keep whatever limit they had at the time.")
        }
    }

    private var thisMonthSection: some View {
        Section {
            HStack {
                Text(Decimal.localCurrencyCode)
                    .foregroundStyle(.secondary)
                TextField("Same as ongoing limit", text: $overrideText)
                    .keyboardType(.decimalPad)
                    .monospacedDigit()
            }

            if hasOverride {
                Button("Remove this month's adjustment", role: .destructive) {
                    showingRemoveConfirm = true
                }
            }
        } header: {
            Text("\(displayMonthLabel) only")
        } footer: {
            Text("A one-off amount for this month. Leave blank to use the ongoing limit.")
        }
        .confirmationDialog(
            "Remove this month's adjustment?",
            isPresented: $showingRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                category.clearOverride(forMonth: month, year: year, context: context)
                overrideText = ""
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - State

    private var hasOverride: Bool {
        category.budgetOverrides.contains { $0.month == month && $0.year == year }
    }

    private var displayMonthLabel: String {
        var comps = DateComponents()
        comps.month = month
        comps.year = year
        let date = Calendar.current.date(from: comps) ?? .now
        return date.monthYearLabel
    }

    /// Pre-fills both fields with whatever is currently set, so saving
    /// without touching anything is a no-op rather than a wipe.
    private func loadCurrentValues() {
        if let existing = category.defaultMonthlyLimit {
            defaultText = "\(existing)"
        }
        if let override = category.budgetOverrides.first(where: { $0.month == month && $0.year == year }) {
            overrideText = "\(override.monthlyLimit)"
        }
    }

    // MARK: - Saving

    private func save() {
        let newDefault = Decimal.parse(defaultText)

        // Only route through changeDefaultLimit when the value actually
        // changed — calling it needlessly would write override rows for
        // every past month for no reason.
        if newDefault != category.defaultMonthlyLimit {
            category.changeDefaultLimit(to: newDefault, context: context)
        }

        if let override = Decimal.parse(overrideText), override > 0 {
            category.setOverride(override, forMonth: month, year: year, context: context)
        } else if overrideText.isEmpty && hasOverride {
            category.clearOverride(forMonth: month, year: year, context: context)
        }

        dismiss()
    }
}
