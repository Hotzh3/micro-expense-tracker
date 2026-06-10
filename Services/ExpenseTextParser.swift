import Foundation

struct ExpenseParseResult: Equatable {
    let amount: Double?
    let merchant: String
    let rawMerchant: String?
    let category: ExpenseCategory
    let confidence: Double
    let source: ExpenseSource
    let summary: String

    var normalizedMerchant: String {
        merchant
    }
}

final class ExpenseTextParser {
    func parse(_ text: String, categories: [ExpenseCategory]) -> ExpenseParseResult? {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else { return nil }

        let amount = extractAmount(from: normalizedText)
        let lowercasedText = normalizedText.lowercased()
        let merchant = extractMerchant(from: normalizedText)
        let category = category(for: lowercasedText, merchant: merchant, categories: categories)
        let confidence = safeConfidence(
            amount: amount,
            merchant: merchant,
            category: category
        )
        let summary = makeSummary(amount: amount, merchant: merchant, category: category)

        return ExpenseParseResult(
            amount: amount,
            merchant: merchant,
            rawMerchant: merchant.isEmpty ? nil : merchant,
            category: category,
            confidence: confidence,
            source: .parsedText,
            summary: summary
        )
    }

    private func extractAmount(from text: String) -> Double? {
        let tokens = tokenize(text)
        if let amount = amountFromCurrencyPrefix(in: text) {
            return amount
        }

        if let amount = amountAfterMXNToken(tokens: tokens) {
            return amount
        }

        if let amount = amountFromTokenSequence(tokens: tokens) {
            return amount
        }

        return nil
    }

    private func amountFromCurrencyPrefix(in text: String) -> Double? {
        let searchText = text.lowercased()
        guard let dollarIndex = searchText.firstIndex(of: "$") else { return nil }

        let afterDollar = searchText[searchText.index(after: dollarIndex)...]
        let candidate = leadingAmountCandidate(from: String(afterDollar))
        return parseAmount(candidate)
    }

    private func amountAfterMXNToken(tokens: [String]) -> Double? {
        for index in tokens.indices {
            let token = tokens[index].lowercased()
            if token == "mxn" || token == "mxn:" || token == "mxn." {
                let nextIndex = tokens.index(after: index)
                if nextIndex < tokens.endIndex {
                    if let amount = parseAmount(tokens[nextIndex]) {
                        return amount
                    }
                }
            }
        }

        return nil
    }

    private func amountFromTokenSequence(tokens: [String]) -> Double? {
        for token in tokens {
            if let amount = parseAmount(token) {
                return amount
            }
        }

        return nil
    }

    private func extractMerchant(from text: String) -> String {
        let lowercased = text.lowercased()

        if let enMerchant = merchantAfterKeyword("en", in: lowercased) {
            return enMerchant
        }

        for (needle, canonical) in knownMerchantPatterns {
            if lowercased.contains(needle) {
                return canonical
            }
        }

        return ""
    }

    private func merchantAfterKeyword(_ keyword: String, in text: String) -> String? {
        let tokens = tokenize(text)
        for index in tokens.indices {
            if tokens[index].lowercased() != keyword {
                continue
            }

            let nextIndex = tokens.index(after: index)
            guard nextIndex < tokens.endIndex else { return nil }

            var merchantTokens: [String] = []
            for token in tokens[nextIndex...] {
                let cleaned = cleanMerchantToken(token)
                if cleaned.isEmpty {
                    continue
                }

                if isMerchantBoundary(cleaned) {
                    break
                }

                merchantTokens.append(cleaned)
                if merchantTokens.count == 3 {
                    break
                }
            }

            let candidate = merchantTokens.joined(separator: " ")
            return candidate.isEmpty ? nil : canonicalMerchantName(for: candidate)
        }

        return nil
    }

    private func canonicalMerchantName(for candidate: String) -> String {
        let lowercased = candidate.lowercased()
        for (needle, canonical) in knownMerchantPatterns {
            if lowercased.contains(needle) {
                return canonical
            }
        }
        return candidate
    }

    private func category(for text: String, merchant: String, categories: [ExpenseCategory]) -> ExpenseCategory {
        let combined = "\(text) \(merchant.lowercased())"

        if containsAny(combined, needles: ["oxxo", "7-eleven", "7 eleven", "seven eleven"]) {
            return category(named: "Convenience", in: categories) ?? .other
        }

        if containsAny(combined, needles: ["starbucks", "coffee", "cafe", "café"]) {
            return category(named: "Coffee", in: categories) ?? .other
        }

        if containsAny(combined, needles: ["uber", "didi"]) {
            return category(named: "Transport", in: categories) ?? .other
        }

        if containsAny(combined, needles: ["spotify", "netflix"]) {
            return category(named: "Entertainment", in: categories) ?? .other
        }

        if combined.contains("amazon") || combined.contains("apple.com/bill") {
            return category(named: "Shopping", in: categories) ?? .other
        }

        if containsAny(combined, needles: ["toks", "taco", "tacos", "restaurante", "restaurant"]) {
            return category(named: "Food", in: categories) ?? .other
        }

        return category(named: "Other", in: categories) ?? categories.last ?? .other
    }

    private func safeConfidence(amount: Double?, merchant: String, category: ExpenseCategory) -> Double {
        var score: Double = 0.45

        if amount != nil {
            score += 0.35
        }

        if !merchant.isEmpty {
            score += 0.12
        }

        if category != .other {
            score += 0.08
        }

        if !score.isFinite {
            return 0.5
        }

        return min(max(score, 0), 1)
    }

    private func makeSummary(amount: Double?, merchant: String, category: ExpenseCategory) -> String {
        var parts: [String] = []
        if let amount {
            parts.append(String(format: "$%.2f", amount))
        }
        if !merchant.isEmpty {
            parts.append(merchant)
        }
        parts.append(category.displayName)

        if parts.isEmpty {
            return "No clear amount or merchant was found."
        }

        return "Parsed from pasted text: " + parts.joined(separator: " • ")
    }

    private func parseAmount(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let cleaned = trimmed
            .replacingOccurrences(of: "mxn", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleaned.contains(where: { $0.isNumber }) else { return nil }
        guard let amount = Double(cleaned), amount.isFinite, amount > 0 else { return nil }
        return amount
    }

    private func leadingAmountCandidate(from text: String) -> String {
        var candidate = ""
        for character in text {
            if character.isNumber || character == "." || character == "," {
                candidate.append(character)
                continue
            }
            break
        }
        return candidate
    }

    private func tokenize(_ text: String) -> [String] {
        text
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map(String.init)
    }

    private func cleanMerchantToken(_ token: String) -> String {
        token
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ":,./-!()[]{}"))
    }

    private func isMerchantBoundary(_ token: String) -> Bool {
        let lower = token.lowercased()
        return ["mxn", "card", "compra", "cargo", "pago", "payment", "charge", "approved", "aprobada", "aprobado", "$"].contains(lower)
    }

    private func containsAny(_ text: String, needles: [String]) -> Bool {
        for needle in needles {
            if text.contains(needle) {
                return true
            }
        }
        return false
    }

    private func category(named name: String, in categories: [ExpenseCategory]) -> ExpenseCategory? {
        categories.first(where: { $0.displayName.lowercased() == name.lowercased() })
    }

    private var knownMerchantPatterns: [(needle: String, canonical: String)] {
        [
            ("starbucks", "Starbucks"),
            ("oxxo", "OXXO"),
            ("7-eleven", "7-Eleven"),
            ("7 eleven", "7-Eleven"),
            ("seven eleven", "7-Eleven"),
            ("uber", "Uber"),
            ("didi", "DiDi"),
            ("spotify", "Spotify"),
            ("netflix", "Netflix"),
            ("amazon", "Amazon"),
            ("apple.com/bill", "Apple"),
            ("toks", "Toks")
        ]
    }
}
