import Foundation

extension Decimal {

    /// The currency code for whatever region the phone is set to.
    /// Falls back to USD only if the system somehow reports none.
    static var localCurrencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    /// "RM 1,234.50" / "$1,234.50" — full currency formatting.
    var asCurrency: String {
        formatted(.currency(code: Decimal.localCurrencyCode))
    }

    /// Currency with no decimals — "RM 1,235".
    /// Useful for charts and summary tiles where cents are noise.
    var asCurrencyRounded: String {
        formatted(
            .currency(code: Decimal.localCurrencyCode)
                .precision(.fractionLength(0))
        )
    }

    /// Always shows a leading + or − sign.
    /// For transaction rows, where direction matters more than the raw number.
    var asSignedCurrency: String {
        let formatted = magnitude.asCurrency
        if self < 0 { return "−\(formatted)" }
        if self > 0 { return "+\(formatted)" }
        return formatted
    }

    /// Bridges to Double, needed by SwiftUI's ProgressView and Swift Charts,
    /// which don't accept Decimal. Only ever use this for DISPLAY —
    /// never route actual money math back through Double.
    var asDouble: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    /// Parses user input from a text field. Strips currency symbols,
    /// spaces, and thousands separators so "RM 1,200" or "1 200.50"
    /// still work. Returns nil if it isn't a valid number.
    static func parse(_ input: String) -> Decimal? {
        let cleaned = input
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".-")).inverted)

        guard !cleaned.isEmpty else { return nil }
        return Decimal(string: cleaned)
    }
}
