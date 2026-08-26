import SwiftUI
import SwiftData

/// The Settings tab: a hub linking to management screens, plus app-level
/// toggles. Deliberately thin — the real work lives in the screens it
/// links to.
struct SettingsView: View {

    @Query private var accounts: [Account]
    @Query private var categories: [Category]

    /// @AppStorage writes straight to UserDefaults. Fine for a simple
    /// preference flag like this; anything with structure belongs in
    /// SwiftData instead.
    @AppStorage("requireBiometricUnlock") private var requireBiometricUnlock = false

    var body: some View {
        List {
            Section("Manage") {
                NavigationLink {
                    ManageAccountsView()
                } label: {
                    LabeledContent {
                        Text("\(accounts.count)")
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Accounts", systemImage: "creditcard.fill")
                    }
                }

                NavigationLink {
                    ManageCategoriesView()
                } label: {
                    LabeledContent {
                        Text("\(categories.count)")
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Categories", systemImage: "tag.fill")
                    }
                }
            }

            Section {
                Toggle(isOn: $requireBiometricUnlock) {
                    Label("Require Face ID", systemImage: "faceid")
                }
            } header: {
                Text("Privacy")
            } footer: {
                Text("Ask for Face ID each time the app opens. Your data never leaves this device.")
            }

            Section {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Currency", value: Decimal.localCurrencyCode)
            } header: {
                Text("About")
            } footer: {
                Text("Currency follows your device region and is recorded with each transaction at the time you enter it.")
            }
        }
        .navigationTitle("Settings")
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(for: [Account.self, Category.self, Budget.self, Transaction.self])
}
