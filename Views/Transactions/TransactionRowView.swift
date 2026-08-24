import SwiftUI

/// One row in the transaction list. Kept in its own file because it's
/// reused in several places later (search results, category detail).
struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {

            // Category icon in a tinted circle. Falls back to a neutral
            // symbol when the transaction has no category assigned.
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: transaction.category?.icon ?? "questionmark.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                // Note is optional, so fall back to the category name,
                // then to a generic label — a row should never look blank.
                Text(primaryLabel)
                    .font(.body)
                    .lineLimit(1)

                Text(secondaryLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Expenses read red and negative, income green and positive.
            // Uses the transaction's OWN stored currency, not the
            // phone's current region.
            Text(transaction.formattedSignedAmount)
                .font(.body.weight(.medium))
                .foregroundStyle(transaction.type == .expense ? .primary : Color.green)
                .monospacedDigit() // keeps amounts vertically aligned
        }
        .padding(.vertical, 4)
    }

    private var primaryLabel: String {
        if !transaction.note.isEmpty { return transaction.note }
        if let name = transaction.category?.name { return name }
        return transaction.type.rawValue
    }

    private var secondaryLabel: String {
        let account = transaction.account?.name
        let date = transaction.date.shortDayLabel
        if let account { return "\(date) · \(account)" }
        return date
    }

    private var categoryColor: Color {
        Color(hex: transaction.category?.colorHex ?? "#8E8E93")
    }
}

// MARK: - Hex color support
// SwiftUI has no built-in hex initializer, and we store category colors
// as hex strings, so this bridges the two.
extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b: Double
        switch cleaned.count {
        case 6:
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
        default:
            // Unrecognized format — fall back to a neutral grey rather
            // than crashing or rendering something invisible.
            r = 0.56; g = 0.56; b = 0.58
        }

        self.init(red: r, green: g, blue: b)
    }
}