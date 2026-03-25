import Foundation
import SwiftData

struct TagSuggester {
    static let knownTags: [String: String] = [
        // English canonical
        "legs": "legs", "leg": "legs", "quads": "legs", "quadriceps": "legs", "hamstrings": "legs", "calves": "legs",
        "chest": "chest", "pectorals": "chest", "pecs": "chest",
        "back": "back", "lats": "back", "upper back": "back", "lat": "back",
        "shoulders": "shoulders", "shoulder": "shoulders", "delts": "shoulders",
        "biceps": "biceps", "bicep": "biceps",
        "triceps": "triceps", "tricep": "triceps",
        "abs": "abs", "core": "abs", "abdominals": "abs",
        "glutes": "glutes", "glute": "glutes",
        // Turkish aliases
        "bacak": "legs", "bcak": "legs", "bakac": "legs",
        "gogus": "chest", "göğüs": "chest", "gögüs": "chest",
        "sirt": "back", "sırt": "back",
        "omuz": "shoulders", "omzu": "shoulders",
        "biseps": "biceps",
        "triseps": "triceps",
        "karin": "abs", "karın": "abs",
        "kalca": "glutes", "kalça": "glutes", "popo": "glutes",
        "on kol": "biceps", "arka kol": "triceps",
        "ust govde": "upper body", "üst gövde": "upper body", "upper": "upper body",
        "alt govde": "lower body", "alt gövde": "lower body", "lower": "lower body",
    ]

    static func suggest(for input: String) -> String {
        let cleaned = input.lowercased().trimmingCharacters(in: .whitespaces)
        if let exact = knownTags[cleaned] {
            return exact
        }

        var bestMatch: (String, Int)?
        for (alias, canonical) in knownTags {
            let dist = levenshteinDistance(cleaned, alias)
            if dist <= 2 {
                if bestMatch == nil || dist < (bestMatch?.1 ?? Int.max) {
                    bestMatch = (canonical, dist)
                }
            }
        }

        return bestMatch?.0 ?? cleaned
    }

    static func suggestions(for input: String, existingTags: [String]) -> [String] {
        let cleaned = input.lowercased().trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return existingTags.sorted() }

        var resultSet = Set<String>()
        var results: [String] = []

        for tag in existingTags {
            if (tag.contains(cleaned) || cleaned.contains(tag)) && !resultSet.contains(tag) {
                resultSet.insert(tag)
                results.append(tag)
            }
        }

        let knownCanonical = Set(knownTags.values)
        for tag in knownCanonical {
            if tag.contains(cleaned) && !resultSet.contains(tag) {
                resultSet.insert(tag)
                results.append(tag)
            }
        }

        for (alias, canonical) in knownTags {
            if levenshteinDistance(cleaned, alias) <= 2 && !resultSet.contains(canonical) {
                resultSet.insert(canonical)
                results.append(canonical)
            }
        }

        return results.sorted()
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
