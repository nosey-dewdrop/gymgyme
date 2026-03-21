import Foundation
import SwiftData

struct TagSuggester {
    // Common tags with aliases/typos that map to the correct tag
    static let knownTags: [String: String] = [
        // Turkish
        "bacak": "bacak", "bcak": "bacak", "bakac": "bacak", "backa": "bacak",
        "gogus": "gogus", "göğüs": "gogus", "gögüs": "gogus", "gogüs": "gogus", "chest": "gogus",
        "sirt": "sirt", "sırt": "sirt", "back": "sirt",
        "omuz": "omuz", "omzu": "omuz", "shoulders": "omuz",
        "biceps": "biceps", "biseps": "biceps", "bicep": "biceps",
        "triceps": "triceps", "triseps": "triceps", "tricep": "triceps",
        "karin": "karin", "karın": "karin", "core": "karin", "abs": "karin",
        "kalca": "kalca", "kalça": "kalca", "glutes": "kalca", "popo": "kalca",
        "on kol": "biceps", "arka kol": "triceps",
        "ust govde": "ust govde", "üst gövde": "ust govde", "upper": "ust govde",
        "alt govde": "alt govde", "alt gövde": "alt govde", "lower": "alt govde",
        "legs": "bacak", "leg": "bacak",
    ]

    static func suggest(for input: String) -> String {
        let cleaned = input.lowercased().trimmingCharacters(in: .whitespaces)
        if let exact = knownTags[cleaned] {
            return exact
        }

        // Fuzzy: find closest known tag
        var bestMatch: (String, Int)?
        for (alias, canonical) in knownTags {
            let dist = levenshteinDistance(cleaned, alias)
            if dist <= 2 { // allow up to 2 typos
                if bestMatch == nil || dist < bestMatch!.1 {
                    bestMatch = (canonical, dist)
                }
            }
        }

        return bestMatch?.0 ?? cleaned
    }

    static func suggestions(for input: String, existingTags: [String]) -> [String] {
        let cleaned = input.lowercased().trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return existingTags.sorted() }

        var results: [String] = []

        // Existing tags that match
        results += existingTags.filter { $0.contains(cleaned) || cleaned.contains($0) }

        // Known tags that match
        let knownCanonical = Set(knownTags.values)
        for tag in knownCanonical {
            if tag.contains(cleaned) && !results.contains(tag) {
                results.append(tag)
            }
        }

        // Fuzzy matches
        for (alias, canonical) in knownTags {
            if levenshteinDistance(cleaned, alias) <= 2 && !results.contains(canonical) {
                results.append(canonical)
            }
        }

        return Array(Set(results)).sorted()
    }

    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)
        let m = s1.count
        let n = s2.count

        if m == 0 { return n }
        if n == 0 { return m }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = s1[i - 1] == s2[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }

        return matrix[m][n]
    }
}
