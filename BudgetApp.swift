import SwiftUI
import SwiftData

/// The app's entry point. Replaces whatever Xcode auto-generated when
/// you created the project (the file named BudgetAppApp.swift or similar).
///
/// If Xcode named the struct differently, keep ITS name — the @main
/// attribute must sit on exactly one struct in the whole project.
@main
struct BudgetApp: App {

    /// The container holding all four models. Built once here and shared
    /// through the environment, which is what makes @Query and
    /// @Environment(\.modelContext) work in every view below.
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Account.self, Category.self, Budget.self, Transaction.self
            )
        } catch {
            // If the container can't be created the app genuinely cannot
            // function, so crashing with a clear message beats limping on.
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Seed on first launch only — the service handles that check.
        // mainContext is used because seeding is quick and happens
        // before any UI appears.
        SeedDataService.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
