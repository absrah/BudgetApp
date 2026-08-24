import Foundation
import SwiftData

/// Populates the database with sensible starting data the first time the
/// app runs, so the add-transaction form isn't staring at empty pickers.
///
/// Everything here is editable or deletable by you later — these are
/// starting points, not fixed values.
enum SeedDataService {

    /// Key tracking whether we've already seeded. Stored in UserDefaults
    /// rather than checking "is the database empty?" — otherwise deleting
    /// all your categories on purpose would silently recreate them.
    private static let hasSeededKey = "hasSeededDefaultData"

    static func seedIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: hasSeededKey) else { return }

        for category in defaultCategories {
            context.insert(category)
        }
        for account in defaultAccounts {
            context.insert(account)
        }

        // save() throws, so handle it rather than force-trying. A failure
        // here isn't worth crashing over — the app still works, you'd
        // just add categories manually.
        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: hasSeededKey)
        } catch {
            print("Seeding failed: \(error)")
        }
    }

    /// Wipes the flag so the next launch re-seeds. Wired to a debug
    /// button in Settings later — handy while developing.
    static func resetSeedFlag() {
        UserDefaults.standard.set(false, forKey: hasSeededKey)
    }

    // MARK: - Defaults

    /// Icons are SF Symbols; colors are hex strings read by Color(hex:).
    /// No default limits set — you assign those in the Budgets tab, and
    /// they auto-carry month to month from there.
    private static var defaultCategories: [Category] {
        [
            Category(name: "Groceries",     icon: "cart.fill",              colorHex: "#34C759"),
            Category(name: "Rent",          icon: "house.fill",             colorHex: "#5856D6"),
            Category(name: "Transport",     icon: "car.fill",               colorHex: "#007AFF"),
            Category(name: "Eating Out",    icon: "fork.knife",             colorHex: "#FF9500"),
            Category(name: "Utilities",     icon: "bolt.fill",              colorHex: "#FFCC00"),
            Category(name: "Phone & Data",  icon: "antenna.radiowaves.left.and.right", colorHex: "#00C7BE"),
            Category(name: "Health",        icon: "heart.fill",             colorHex: "#FF2D55"),
            Category(name: "Education",     icon: "book.fill",              colorHex: "#AF52DE"),
            Category(name: "Shopping",      icon: "bag.fill",               colorHex: "#FF3B30"),
            Category(name: "Entertainment", icon: "gamecontroller.fill",    colorHex: "#A2845E"),
            Category(name: "Savings",       icon: "banknote.fill",          colorHex: "#30B0C7"),
            Category(name: "Other",         icon: "tag.fill",               colorHex: "#8E8E93")
        ]
    }

    /// Two accounts to start: a bank account and cash. Rename them to
    /// match your real ones in Settings.
    private static var defaultAccounts: [Account] {
        [
            Account(name: "Main Account", type: .checking, openingBalance: 0),
            Account(name: "Cash",         type: .cash,     openingBalance: 0)
        ]
    }
}
