import SwiftUI

/// The app's spine: a four-tab bar matching the structure we planned.
/// Every other screen lives inside one of these tabs.
struct RootView: View {

    // Remembers which tab you were on if the view is recreated.
    @State private var selectedTab: Tab = .transactions

    enum Tab {
        case transactions, budgets, reports, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            // Each tab gets its own NavigationStack so it keeps its own
            // independent navigation history — switching tabs doesn't
            // reset where you were in another one.
            NavigationStack {
                TransactionListView()
            }
            .tabItem {
                Label("Transactions", systemImage: "list.bullet.rectangle")
            }
            .tag(Tab.transactions)

            NavigationStack {
                BudgetListView()
            }
            .tabItem {
                Label("Budgets", systemImage: "chart.pie.fill")
            }
            .tag(Tab.budgets)

            NavigationStack {
                ReportsView()
            }
            .tabItem {
                Label("Reports", systemImage: "chart.xyaxis.line")
            }
            .tag(Tab.reports)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
    }
}

// MARK: - Temporary placeholders
// These exist only so the project compiles and runs before the real
// screens are written. Delete each one as you build its real version.
// BudgetListView has been removed — the real one now lives in
// Views/Budgets/BudgetListView.swift.

struct ReportsView: View {
    var body: some View {
        ContentUnavailableView(
            "Reports",
            systemImage: "chart.xyaxis.line",
            description: Text("Coming in step 7.")
        )
        .navigationTitle("Reports")
    }
}

struct SettingsView: View {
    var body: some View {
        ContentUnavailableView(
            "Settings",
            systemImage: "gearshape",
            description: Text("Coming later.")
        )
        .navigationTitle("Settings")
    }
}

#Preview {
    RootView()
}