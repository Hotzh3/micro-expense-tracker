import Foundation

struct MerchantProfile {
    let canonicalName: String
    let aliases: [String]
    let defaultCategory: ExpenseCategory
    let symbolName: String?
}

struct MerchantMatch {
    let rawMerchant: String
    let normalizedMerchant: String
    let category: ExpenseCategory
    let symbolName: String?
    let matchedAlias: String

    var isKnownMerchant: Bool {
        true
    }
}

final class MerchantNormalizer {
    static let shared = MerchantNormalizer()

    let profiles: [MerchantProfile] = [
        .init(canonicalName: "Starbucks", aliases: ["starbucks", "starbucks coffee", "starbucks reforma", "starbucks mx", "sbx", "starbucks coffee mx"], defaultCategory: .coffee, symbolName: "cup.and.saucer.fill"),
        .init(canonicalName: "Uber", aliases: ["uber", "uber trip"], defaultCategory: .transport, symbolName: "car.fill"),
        .init(canonicalName: "Uber Eats", aliases: ["uber eats"], defaultCategory: .food, symbolName: "takeoutbag.and.cup.and.straw.fill"),
        .init(canonicalName: "Spotify", aliases: ["spotify", "spotify mx"], defaultCategory: .entertainment, symbolName: "music.note"),
        .init(canonicalName: "Netflix", aliases: ["netflix", "netflix.com"], defaultCategory: .entertainment, symbolName: "play.rectangle.fill"),
        .init(canonicalName: "OXXO", aliases: ["oxxo", "oxxo suc", "oxxo suc 123"], defaultCategory: .convenience, symbolName: "bag.fill"),
        .init(canonicalName: "7-Eleven", aliases: ["7-eleven", "7 eleven", "seven eleven", "7 eleven mx"], defaultCategory: .convenience, symbolName: "bag.fill"),
        .init(canonicalName: "Amazon", aliases: ["amazon", "amazon.com", "amazon mexico"], defaultCategory: .shopping, symbolName: "cart.fill"),
        .init(canonicalName: "Toks", aliases: ["toks", "restaurant toks", "restaurante toks"], defaultCategory: .food, symbolName: "fork.knife"),
        .init(canonicalName: "Mercado Pago", aliases: ["mercado pago"], defaultCategory: .other, symbolName: "creditcard.fill"),
        .init(canonicalName: "Apple", aliases: ["apple.com/bill", "apple bill", "apple.com", "apple"], defaultCategory: .shopping, symbolName: "apple.logo"),
        .init(canonicalName: "DiDi", aliases: ["didi", "didi trip"], defaultCategory: .transport, symbolName: "car.fill")
    ]

    func normalize(candidate: String) -> MerchantMatch? {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalizedCandidate = normalizeKey(trimmed)
        let bestProfile = profiles.compactMap { profile -> (profile: MerchantProfile, alias: String, score: Int)? in
            let bestAlias = profile.aliases.compactMap { alias -> (alias: String, score: Int)? in
                let normalizedAlias = normalizeKey(alias)
                guard !normalizedAlias.isEmpty else { return nil }

                if normalizedCandidate == normalizedAlias {
                    return (alias: alias, score: 1000 + normalizedAlias.count)
                }

                guard normalizedCandidate.contains(normalizedAlias) else { return nil }
                return (alias: alias, score: normalizedAlias.count)
            }
            .sorted { $0.score > $1.score }
            .first

            guard let bestAlias else { return nil }
            return (profile: profile, alias: bestAlias.alias, score: bestAlias.score)
        }
        .sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.profile.canonicalName < rhs.profile.canonicalName
            }
            return lhs.score > rhs.score
        }
        .first

        guard let bestProfile else { return nil }

        return MerchantMatch(
            rawMerchant: trimmed,
            normalizedMerchant: bestProfile.profile.canonicalName,
            category: bestProfile.profile.defaultCategory,
            symbolName: bestProfile.profile.symbolName,
            matchedAlias: bestProfile.alias
        )
    }

    func bestMatch(in text: String) -> MerchantMatch? {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        if let match = normalize(candidate: cleaned) {
            return match
        }

        let tokens = cleaned
            .split(whereSeparator: { $0.isWhitespace || $0 == "," || $0 == "." || $0 == ":" || $0 == "/" })
            .map(String.init)

        let windows = slidingWindows(of: tokens, maxLength: 4)
        for window in windows {
            let candidate = window.joined(separator: " ")
            if let match = normalize(candidate: candidate) {
                return MerchantMatch(
                    rawMerchant: candidate,
                    normalizedMerchant: match.normalizedMerchant,
                    category: match.category,
                    symbolName: match.symbolName,
                    matchedAlias: match.matchedAlias
                )
            }
        }

        return nil
    }

    func boostConfidence(for match: MerchantMatch?) -> Double {
        guard let match else { return 0 }
        switch match.normalizedMerchant {
        case "Starbucks", "Uber", "Uber Eats", "Spotify", "Netflix", "OXXO", "7-Eleven", "Amazon", "Toks", "Apple", "DiDi":
            return 0.14
        default:
            return 0.08
        }
    }

    private func normalizeKey(_ value: String) -> String {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func slidingWindows(of tokens: [String], maxLength: Int) -> [[String]] {
        guard !tokens.isEmpty else { return [] }

        var windows: [[String]] = []
        for length in stride(from: maxLength, through: 1, by: -1) {
            guard tokens.count >= length else { continue }
            for start in 0...(tokens.count - length) {
                windows.append(Array(tokens[start..<(start + length)]))
            }
        }
        return windows
    }
}
