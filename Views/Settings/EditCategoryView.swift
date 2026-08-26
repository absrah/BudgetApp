import SwiftUI
import SwiftData

struct EditCategoryView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allCategories: [Category]

    private let editing: Category?

    @State private var name: String = ""
    @State private var icon: String = "tag.fill"
    @State private var colorHex: String = "#4A90D9"

    init() { editing = nil }
    init(category: Category) { editing = category }

    /// A fixed palette rather than a freeform color picker: it keeps
    /// categories visually distinct and readable in charts, which an
    /// arbitrary colour wheel doesn't guarantee.
    private let palette = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#00C7BE", "#007AFF", "#5856D6", "#AF52DE",
        "#FF2D55", "#A2845E", "#30B0C7", "#8E8E93"
    ]

    private let icons = [
        "cart.fill", "house.fill", "car.fill", "fork.knife",
        "bolt.fill", "antenna.radiowaves.left.and.right", "heart.fill", "book.fill",
        "bag.fill", "gamecontroller.fill", "banknote.fill", "tag.fill",
        "airplane", "tram.fill", "cup.and.saucer.fill", "gift.fill",
        "pawprint.fill", "wrench.and.screwdriver.fill", "graduationcap.fill", "stethoscope"
    ]

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 12)]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: colorHex).opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color(hex: colorHex))
                        }
                        TextField("Name", text: $name)
                    }

                    if let error = validationError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Colour") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(palette, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if hex == colorHex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Icon") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(icons, id: \.self) { symbol in
                            Image(systemName: symbol)
                                .font(.system(size: 18))
                                .frame(width: 36, height: 36)
                                .foregroundStyle(symbol == icon ? Color(hex: colorHex) : .secondary)
                                .background(
                                    Circle()
                                        .fill(symbol == icon
                                              ? Color(hex: colorHex).opacity(0.15)
                                              : Color.clear)
                                )
                                .onTapGesture { icon = symbol }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(editing == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(validationError != nil || trimmedName.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var validationError: String? {
        guard !trimmedName.isEmpty else { return nil }
        if Category.nameExists(trimmedName, in: allCategories, excluding: editing) {
            return "A category with this name already exists."
        }
        return nil
    }

    private func load() {
        guard let editing else { return }
        name = editing.name
        icon = editing.icon
        colorHex = editing.colorHex
    }

    /// Note: the budget limit is NOT edited here — that lives in the
    /// Budgets tab, where changing it correctly freezes past months.
    private func save() {
        if let editing {
            editing.name = trimmedName
            editing.icon = icon
            editing.colorHex = colorHex
        } else {
            context.insert(
                Category(name: trimmedName, icon: icon, colorHex: colorHex)
            )
        }
        dismiss()
    }
}
