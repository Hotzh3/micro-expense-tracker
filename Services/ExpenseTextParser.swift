import Foundation

struct ExpenseParseResult: Equatable {
    let amount: Double?
    let merchant: String
    let category: ExpenseCategory
    let confidence: Double
    let source: ExpenseSource
    let summary: String
}

final class ExpenseTextParser {
    private struct MerchantRule {
        let canonicalName: String
        let category: ExpenseCategory
        let aliases: [String]
    }

    private static let merchantRules: [MerchantRule] = [
        .init(canonicalName: "OXXO", category: .convenience, aliases: ["oxxo"]),
        .init(canonicalName: "7-Eleven", category: .convenience, aliases: ["7-eleven", "7 eleven", "seven eleven"]),
        .init(canonicalName: "Starbucks Coffee", category: .coffee, aliases: ["starbucks coffee", "starbucks"]),
        .init(canonicalName: "Uber", category: .transport, aliases: ["uber"]),
        .init(canonicalName: "DiDi", category: .transport, aliases: ["didi"]),
        .init(canonicalName: "Spotify", category: .entertainment, aliases: ["spotify"]),
        .init(canonicalName: "Netflix", category: .entertainment, aliases: ["netflix"]),
        .init(canonicalName: "Amazon", category: .shopping, aliases: ["amazon"]),
        .init(canonicalName: "Toks", category: .food, aliases: ["toks"]),
        .init(canonicalName: "Mercado Pago", category: .other, aliases: ["mercado pago"])
    ]

    private static let amountPatterns: [String] = [
        #"(?:MXN|mxn|\$)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:[.,][0-9]{1,2})?|[0-9]+(?:[.,][0-9]{1,2})?)"#,
        #"\b(?:por|de|for|amount of|importe|monto|total)\s*(?:MXN|mxn|\$)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:[.,][0-9]{1,2})?|[0-9]+(?:[.,][0-9]{1,2})?)"#,
        #"\b(?:compra|cargo|pago|retiro|purchase|charge|payment|transaction|txn)\s*(?:de|por)?\s*(?:MXN|mxn|\$)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:[.,][0-9]{1,2})?|[0-9]+(?:[.,][0-9]{1,2})?)"#,
        #"\b([0-9]{1,3}(?:,[0-9]{3})+(?:[.,][0-9]{1,2})?)\b"#,
        #"\b([0-9]+(?:[.,][0-9]{1,2})?)\b"#
    ]

    private static let merchantPrefixes: [String] = [
        "en",
        "at",
        "in",
        "comercio",
        "merchant"
    ]

    private static let merchantStopWords: Set<String> = [
        "approved",
        "aprobada",
        "aprobado",
        "compra",
        "cargo",
        "charged",
        "charge",
        "purchase",
        "pago",
        "paid",
        "payment",
        "transaction",
        "transaccion",
        "transacción",
        "retiro",
        "withdrawal",
        "card",
        "tarjeta",
        "terminacion",
        "terminación",
        "autorizacion",
        "autorización",
        "authorization",
        "auth",
        "voucher",
        "num",
        "no",
        "ref",
        "transaction",
        "bank",
        "banco",
        "bbva",
        "nu",
        "mxn",
        "$",
        "por",
        "de",
        "para",
        "en",
        "at",
        "in"
    ]

    func parse(_ text: String, categories: [ExpenseCategory]) -> ExpenseParseResult? {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else { return nil }

        let lowercasedText = normalizedText.lowercased()
        let amount = extractAmount(from: normalizedText)
        let merchant = extractMerchant(from: normalizedText)
        let category = suggestCategory(from: lowercasedText, merchant: merchant, categories: categories)

        let confidence = confidence(for: amount, merchant: merchant, category: category)
        let summary = makeSummary(amount: amount, merchant: merchant, category: category)

        return ExpenseParseResult(
            amount: amount,
            merchant: merchant,
            category: category,
            confidence: confidence,
            source: .parsedText,
            summary: summary
        )
    }

    private func confidence(for amount: Double?, merchant: String, category: ExpenseCategory) -> Double {
        switch (amount != nil, !merchant.isEmpty, category != .other) {
        case (true, true, true):
            return 0.96
        case (true, true, false):
            return 0.84
        case (true, false, true):
            return 0.73
        case (true, false, false):
            return 0.62
        case (false, true, true):
            return 0.38
        case (false, true, false):
            return 0.28
        default:
            return 0.14
        }
    }

    private func makeSummary(amount: Double?, merchant: String, category: ExpenseCategory) -> String {
        let summaryParts: [String] = [
            amount.map { String(format: "$%.2f", $0) },
            merchant.isEmpty ? nil : merchant,
            category.displayName
        ].compactMap { $0 }

        return summaryParts.isEmpty
            ? "No clear amount or merchant was found."
            : "Parsed from pasted text: " + summaryParts.joined(separator: " • ")
    }

    private func extractAmount(from text: String) -> Double? {
        for pattern in Self.amountPatterns {
            if let amount = firstMatchAmount(in: text, pattern: pattern) {
                return amount
            }
        }

        return nil
    }

    private func extractMerchant(from text: String) -> String {
        let normalizedText = normalize(text)

        if let merchantRule = Self.merchantRules.first(where: { rule in
            rule.aliases.contains(where: { alias in
                normalizedText.contains(normalize(alias))
            })
        }) {
            return merchantRule.canonicalName
        }

        if let amountRange = amountRange(in: text) {
            if let candidate = merchantAfterAmount(in: text, amountRange: amountRange) {
                return candidate
            }

            if let candidate = merchantBeforeAmount(in: text, amountRange: amountRange) {
                return candidate
            }
        }

        if let candidate = merchantFromConnectorPhrase(in: text) {
            return candidate
        }

        return ""
    }

    private func merchantAfterAmount(in text: String, amountRange: Range<String.Index>) -> String? {
        let trailingText = text[amountRange.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ":,.-/"))

        guard !trailingText.isEmpty else { return nil }

        let phrase = trailingText
            .split(whereSeparator: { $0.isWhitespace || $0 == "," || $0 == "." || $0 == ":" || $0 == "/" })
            .prefix(4)
            .joined(separator: " ")

        return cleanMerchantCandidate(phrase)
    }

    private func merchantBeforeAmount(in text: String, amountRange: Range<String.Index>) -> String? {
        let leadingText = text[..<amountRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ":,.-/"))

        guard !leadingText.isEmpty else { return nil }

        let normalizedLeading = normalize(String(leadingText))
        if let merchantRule = Self.merchantRules.first(where: { rule in
            rule.aliases.contains(where: { alias in
                normalizedLeading.contains(normalize(alias))
            })
        }) {
            return merchantRule.canonicalName
        }

        let phrase = leadingText
            .split(whereSeparator: { $0.isWhitespace || $0 == "," || $0 == "." || $0 == ":" || $0 == "/" })
            .suffix(4)
            .joined(separator: " ")

        return cleanMerchantCandidate(String(phrase))
    }

    private func merchantFromConnectorPhrase(in text: String) -> String? {
        for prefix in Self.merchantPrefixes {
            let pattern = #"(?i)\b\#(prefix)\b\s+([A-Za-zÀ-ÿ0-9&'().\- ]{2,60})"#
            if let match = firstMatchString(in: text, pattern: pattern) {
                let cleaned = cleanMerchantCandidate(match)
                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        }

        return nil
    }

    private func suggestCategory(from text: String, merchant: String, categories: [ExpenseCategory]) -> ExpenseCategory {
        let normalizedMerchant = normalize(merchant)

        if let directMerchantMatch = Self.merchantRules.first(where: { rule in
            let canonical = normalize(rule.canonicalName)
            return normalizedMerchant.contains(canonical) || rule.aliases.contains(where: { normalizedMerchant.contains(normalize($0)) })
        }) {
            return directMerchantMatch.category
        }

        let combined = "\(text) \(merchant.lowercased())"

        for category in categories {
            if category == .other {
                continue
            }

            if category.keywords.contains(where: { combined.contains($0.lowercased()) }) {
                return category
            }
        }

        if let category = categories.first(where: { $0.displayName == "Other" }) {
            return category
        }

        return categories.first ?? .other
    }

    private func amountRange(in text: String) -> Range<String.Index>? {
        for pattern in Self.amountPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }

            let range = NSRange(text.startIndex..., in: text)
            guard let match = regex.firstMatch(in: text, options: [], range: range) else {
                continue
            }

            if let swiftRange = Range(match.range, in: text) {
                return swiftRange
            }
        }

        return nil
    }

    private func firstMatchAmount(in text: String, pattern: String) -> Double? {
        guard let match = firstMatchString(in: text, pattern: pattern) else { return nil }
        return normalizeAmountString(match).flatMap(Double.init)
    }

    private func firstMatchString(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        if match.numberOfRanges < 2 {
            return nil
        }

        let captureRange = match.range(at: 1)
        guard let swiftRange = Range(captureRange, in: text) else {
            return nil
        }

        return String(text[swiftRange])
    }

    private func normalizeAmountString(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let noCurrency = trimmed
            .replacingOccurrences(of: "MXN", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let normalized: String
        if noCurrency.contains(",") && noCurrency.contains(".") {
            normalized = noCurrency.replacingOccurrences(of: ",", with: "")
        } else if noCurrency.contains(",") {
            let components = noCurrency.split(separator: ",", omittingEmptySubsequences: true)
            if components.count == 2, components.last?.count == 2 {
                normalized = noCurrency.replacingOccurrences(of: ",", with: ".")
            } else {
                normalized = noCurrency.replacingOccurrences(of: ",", with: "")
            }
        } else {
            normalized = noCurrency
        }

        return normalized
    }

    private func cleanMerchantCandidate(_ value: String) -> String {
        let trimmed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,:;!-/"))

        guard !trimmed.isEmpty else { return "" }

        let normalized = normalize(trimmed)
        if let merchantRule = Self.merchantRules.first(where: { rule in
            rule.aliases.contains(where: { normalized.contains(normalize($0)) })
        }) {
            return merchantRule.canonicalName
        }

        let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
        let filtered = parts.filter { !Self.merchantStopWords.contains($0.lowercased()) }
        let candidate = filtered.isEmpty ? trimmed : filtered.joined(separator: " ")

        return candidate
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,:;!-/"))
    }

    private func normalize(_ value: String) -> String {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: " ", with: "-")
    }
}
