import Foundation

extension Decimal {

    /// The phone's current region currency. Used only when creating NEW
    /// records — never for formatting existing ones, which carry their
    /// own stored currencyCode.
    static var localCurrencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    // MARK: - Explicit currency (preferred)

    /// Formats in a specific currency. Always prefer this over the
    /// locale-based version when displaying a stored record.
    func asCurrency(code: String) -> String {
        formatted(.currency(code: code))
    }

    func asCurrencyRounded(code: String) -> String {
        formatted(.currency(code: code).precision(.fractionLength(0)))
    }

    /// Always shows a leading + or −, for transaction rows.
    func asSignedCurrency(code: String) -> String {
        let base = magnitude.asCurrency(code: code)
        if self < 0 { return "−\(base)" }
        if self > 0 { return "+\(base)" }
        return base
    }

    // MARK: - Locale fallback

    /// For values with no currency of their own — totals across the whole
    /// app, chart axes, and so on.
    var asCurrency: String {
        asCurrency(code: Decimal.localCurrencyCode)
    }

    var asCurrencyRounded: String {
        asCurrencyRounded(code: Decimal.localCurrencyCode)
    }

    var asSignedCurrency: String {
        asSignedCurrency(code: Decimal.localCurrencyCode)
    }

    // MARK: - Conversion

    /// Bridge for ProgressView and Swift Charts, which don't take Decimal.
    /// DISPLAY ONLY — never route money math back through Double.
    var asDouble: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    /// Parses text-field input. Strips symbols, spaces and separators so
    /// "RM 1,200" or "1 200.50" work. nil if not a valid number.
    static func parse(_ input: String) -> Decimal? {
        let cleaned = input
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: CharacterSet.decimalDigits
                .union(CharacterSet(charactersIn: ".-")).inverted)

        guard !cleaned.isEmpty else { return nil }
        return Decimal(string: cleaned)
    }
}