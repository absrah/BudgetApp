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

// All four tabs now have real screens — no placeholders remain.

#Preview {
    RootView()
}