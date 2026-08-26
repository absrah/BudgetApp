import SwiftUI
import SwiftData

struct ManageAccountsView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \Account.name) private var accounts: [Account]

    @State private var creating = false
    @State private var editing: Account?
    @State private var pendingDeletion: Account?

    var body: some View {
        List {
            Section {
                ForEach(active) { account in
                    row(account)
                }
            } header: {
                Text("Active")
            }

            if !archived.isEmpty {
                Section {
                    ForEach(archived) { account in
                        row(account)
                    }
                } header: {
                    Text("Archived")
                } footer: {
                    Text("Archived accounts stay in your history but don't appear when adding transactions.")
                }
            }
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { creating = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $creating) { EditAccountView() }
        .sheet(item: $editing) { EditAccountView(account: $0) }
        // Deleting is a confirmation, not a swipe-and-gone, because it
        // orphans every transaction on the account.
        .confirmationDialog(
            "Delete this account?",
            isPresented: .constant(pendingDeletion != nil),
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { account in
            Button("Delete", role: .destructive) {
                context.delete(account)
                pendingDeletion = nil
            }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: { account in
            Text("\(account.transactions.count) transaction(s) will stay in your history but lose their account. Archiving instead keeps everything linked.")
        }
    }

    private func row(_ account: Account) -> some View {
        Button {
            editing = account
        } label: {
            HStack {
                Label(account.name, systemImage: account.type.icon)
                Spacer()
                Text(account.formattedBalance)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                pendingDeletion = account
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                account.isArchived.toggle()
            } label: {
                Label(
                    account.isArchived ? "Restore" : "Archive",
                    systemImage: account.isArchived ? "tray.and.arrow.up" : "archivebox"
                )
            }
            .tint(.orange)
        }
    }

    private var active: [Account] { accounts.filter { !$0.isArchived } }
    private var archived: [Account] { accounts.filter { $0.isArchived } }
}
