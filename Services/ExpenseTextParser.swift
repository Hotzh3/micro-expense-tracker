import Foundation

struct ExpenseParseResult: Equatable {
    let amount: Double?
    let merchant: String
    let category: ExpenseCategory
    let confidence: Double
    let summary: String
}

final class ExpenseTextParser {
    func parse(_ text: String, categories: [ExpenseCategory]) -> ExpenseParseResult? {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else { return nil }

        let lowercasedText = normalizedText.lowercased()
        let amount = extractAmount(from: normalizedText)
        let merchant = extractMerchant(from: normalizedText)
        let category = suggestCategory(from: lowercasedText, merchant: merchant, categories: categories)

        let confidence: Double
        switch (amount != nil, merchant.isEmpty) {
        case (true, false):
            confidence = 0.92
        case (true, true), (false, false):
            confidence = 0.65
        default:
            confidence = 0.3
        }

        let summaryParts: [String] = [
            amount.map { String(format: "$%.2f", $0) },
            merchant.isEmpty ? nil : merchant,
            category.displayName
        ].compactMap { $0 }

        let summary = summaryParts.isEmpty
            ? "No clear amount or merchant was found."
            : "Parsed " + summaryParts.joined(separator: " • ")

        return ExpenseParseResult(
            amount: amount,
            merchant: merchant,
            category: category,
            confidence: confidence,
            summary: summary
        )
    }

    private func extractAmount(from text: String) -> Double? {
        let patterns = [
            #"\$\s*([0-9]+(?:[.,][0-9]{1,2})?)"#,
            #"(?:MXN|mxn)\s*([0-9]+(?:[.,][0-9]{1,2})?)"#,
            #"\b([0-9]+(?:[.,][0-9]{1,2}))\b"#
        ]

        for pattern in patterns {
            if let amount = firstMatch(in: text, pattern: pattern) {
                return amount
            }
        }

        return nil
    }

    private func extractMerchant(from text: String) -> String {
        let merchantPatterns = [
            #"\b(?:en|at|in|para)\s+([A-Za-zÀ-ÿ0-9&'.,\- ]{2,40})"#,
            #"\b(?:en|at|in|para)\s+([A-Za-zÀ-ÿ0-9&'.,\- ]+)$"#
        ]

        for pattern in merchantPatterns {
            if let match = firstMatchString(in: text, pattern: pattern) {
                let cleaned = match
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: ".,:;!-"))
                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        }

        if let bankPrefixRange = text.range(of: ":") {
            let trailingText = text[bankPrefixRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            if let amountRange = trailingText.range(of: #"\$\s*[0-9]+(?:[.,][0-9]{1,2})?"#, options: .regularExpression) {
                let afterAmount = trailingText[amountRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                if let merchant = afterAmount.split(separator: " ").first {
                    let cleaned = String(merchant).trimmingCharacters(in: CharacterSet(charactersIn: ".,:;!-"))
                    if !cleaned.isEmpty {
                        return cleaned
                    }
                }
            }
        }

        return ""
    }

    private func suggestCategory(from text: String, merchant: String, categories: [ExpenseCategory]) -> ExpenseCategory {
        let combined = "\(text) \(merchant.lowercased())"

        for category in categories {
            if category == .other {
                continue
            }

            if category.keywords.contains(where: { combined.contains($0.lowercased()) }) {
                return category
            }
        }

        return categories.first(where: { $0.displayName == "Other" }) ?? categories.first ?? .other
    }

    private func firstMatch(in text: String, pattern: String) -> Double? {
        guard let match = firstMatchString(in: text, pattern: pattern) else { return nil }
        let normalized = match
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(normalized)
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
}
