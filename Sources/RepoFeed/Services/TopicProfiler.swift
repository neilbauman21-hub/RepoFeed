import Foundation

enum TopicProfiler {
    private static let stopWords: Set<String> = [
        "about", "above", "after", "again", "against", "also", "because", "before", "being",
        "below", "between", "both", "build", "built", "button", "can", "code", "could", "does",
        "doing", "each", "example", "from", "github", "have", "having", "here", "into", "just",
        "like", "make", "more", "most", "other", "project", "readme", "repo", "repository", "should",
        "some", "such", "than", "that", "their", "them", "then", "there", "these", "they", "this",
        "through", "under", "using", "very", "want", "what", "when", "where", "which", "while", "will",
        "with", "would", "your", "you", "the", "and", "for", "are", "not", "our", "but", "all", "any",
        "use", "used", "get", "set", "run", "app", "application", "install", "support", "version",
        "async", "await", "case", "class", "const", "data", "else", "false", "file", "files", "func",
        "function", "guard", "import", "interface", "name", "nil", "null", "number", "object", "path",
        "private", "public", "return", "self", "static", "string", "struct", "switch", "throw", "throws",
        "true", "type", "value", "view", "void", "token", "secret", "password", "credential"
    ]

    private static let technologySignals: [(needle: String, label: String)] = [
        ("swiftui", "SwiftUI"), ("typescript", "TypeScript"), ("javascript", "JavaScript"),
        ("react", "React"), ("next.js", "Next.js"), ("python", "Python"), ("django", "Django"),
        ("fastapi", "FastAPI"), ("rust", "Rust"), ("tauri", "Tauri"), ("golang", "Go"),
        ("docker", "Docker"), ("kubernetes", "Kubernetes"), ("cloudflare", "Cloudflare"),
        ("machine learning", "Machine Learning"), ("local-first", "Local-first"),
        ("macos", "macOS"), ("ios", "iOS"), ("sqlite", "SQLite"), ("postgres", "Postgres")
    ]

    static func topics(from text: String, manifestTags: [String] = [], limit: Int = 7) -> [String] {
        let lowercase = text.lowercased()
        var scored: [String: Int] = [:]

        for signal in technologySignals where lowercase.contains(signal.needle) {
            scored[signal.label, default: 0] += 12
        }
        for tag in manifestTags {
            scored[tag, default: 0] += 18
        }

        let words = lowercase.components(separatedBy: CharacterSet.alphanumerics.inverted)
        for word in words where word.count > 3 && word.count < 24 && !stopWords.contains(word) {
            scored[word.capitalized, default: 0] += 1
        }

        return scored
            .sorted { lhs, rhs in lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value }
            .prefix(limit)
            .map(\.key)
    }

    static func title(from markdown: String, fallback: String) -> String {
        for line in markdown.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                return cleanMarkdown(String(trimmed.dropFirst(2)))
            }
        }
        return fallback.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "_", with: " ")
    }

    static func summary(from markdown: String, fallback: String) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        var paragraph: [String] = []

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            let isNoise = line.isEmpty || line.hasPrefix("#") || line.hasPrefix("!") ||
                line.hasPrefix("[") || line.hasPrefix("<") || line.hasPrefix("```") ||
                line.hasPrefix("---") || line.hasPrefix("- [")
            if isNoise {
                if !paragraph.isEmpty { break }
                continue
            }
            paragraph.append(cleanMarkdown(line))
            if paragraph.joined(separator: " ").count > 240 { break }
        }

        let result = paragraph.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { return "A local repository named \(fallback)." }
        return String(result.prefix(320))
    }

    static func cleanPreview(_ markdown: String, limit: Int = 900) -> String {
        markdown
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("!") }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(limit)
            .description
    }

    static func cleanMarkdown(_ value: String) -> String {
        value
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "[*", with: "[")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
