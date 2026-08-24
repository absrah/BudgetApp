import Foundation
import SwiftData

@Model
final class Category {
    var name: String
    var icon: String     // SF Symbol name, e.g. "cart.fill", "house.fill"
    var colorHex: String // stored as a hex string like "#4A90D9"

    // One Category can be used on many Transactions.
    // .nullify means: if a Category is deleted, don't delete the
    // transactions — just clear their category link (safer for
    // financial records than cascading deletes).
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []

    // One Category can have one active Budget (its monthly limit).
    // Optional because a category doesn't need a budget set.
    @Relationship(deleteRule: .cascade)
    var budget: Budget?

    init(name: String, icon: String = "tag.fill", colorHex: String = "#4A90D9") {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}
