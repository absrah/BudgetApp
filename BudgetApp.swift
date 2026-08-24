import SwiftUI
import SwiftData

@main
struct BudgetApp: App {

    // FIX #6: previously this used fatalError, which presents to you as
    // an unexplained crash on launch with no way to tell what went wrong
    // or recover your data. Now a failure shows a readable screen with
    // the actual error, which matters most during schema migrations —
    // exactly when this is likely to break.
    private let container: ModelContainer?
    private let startupError: Error?

    init() {
        do {
            let container = try ModelContainer(
                for: Account.self, Category.self, Budget.self, Transaction.self
            )
            self.container = container
            self.startupError = nil
            SeedDataService.seedIfNeeded(context: container.mainContext)
        } catch {
            self.container = nil
            self.startupError = error
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView()
                    .modelContainer(container)
            } else {
                StartupErrorView(error: startupError)
            }
        }
    }
}

/// Shown only when the database can't be opened. Deliberately plain —
/// it can't rely on anything from the model layer.
struct StartupErrorView: View {
    let error: Error?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)

            Text("Couldn't open your data")
                .font(.title2.weight(.semibold))

            Text("The database failed to load. This usually means the data model changed without a migration.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let error {
                // The raw error, so a failure is diagnosable from the
                // device instead of requiring a Mac and a debugger.
                Text(String(describing: error))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(32)
    }
}