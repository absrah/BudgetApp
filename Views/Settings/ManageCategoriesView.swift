import SwiftUI
import SwiftData

struct ManageCategoriesView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var creating = false
    @State private var editing: Category?
    @State private var pendingDeletion: Category?

    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    editing = category
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: category.colorHex).opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: category.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: category.colorHex))
                        }

                        Text(category.name)

                        Spacer()

                        if let limit = category.defaultMonthlyLimit {
                            Text(limit.asCurrencyRounded)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        pendingDeletion = category
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { creating = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $creating) { EditCategoryView() }
        .sheet(item: $editing) { EditCategoryView(category: $0) }
        .confirmationDialog(
            "Delete this category?",
            isPresented: .constant(pendingDeletion != nil),
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { category in
            Button("Delete", role: .destructive) {
                context.delete(category)
                pendingDeletion = nil
            }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: { category in
            // .nullify on the relationship means the transactions survive.
            Text("\(category.transactions.count) transaction(s) will become uncategorised. Their amounts and dates are kept.")
        }
    }
}
