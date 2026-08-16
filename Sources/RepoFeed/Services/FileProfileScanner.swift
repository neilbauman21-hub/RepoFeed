import Foundation

actor FileProfileScanner {
    private struct Candidate: Sendable {
        let url: URL
        let kind: String
        let technology: String?
        let score: UInt64
    }

    private let ignoredDirectories: Set<String> = [
        ".git", ".build", ".cache", ".gradle", ".idea", ".next", ".nuxt", ".pytest_cache",
        ".swiftpm", ".venv", ".vscode", "build", "coverage", "dist", "DerivedData", "node_modules",
        "Pods", "target", "vendor", "venv"
    ]

    private let technologyByExtension: [String: String] = [
        "swift": "Swift", "m": "Objective-C", "mm": "Objective-C", "ts": "TypeScript", "tsx": "TypeScript",
        "js": "JavaScript", "jsx": "JavaScript", "py": "Python", "rs": "Rust", "go": "Go",
        "java": "Java", "kt": "Kotlin", "kts": "Kotlin", "rb": "Ruby", "php": "PHP",
        "c": "C", "h": "C", "cc": "C++", "cpp": "C++", "hpp": "C++", "cs": "C#",
        "dart": "Dart", "scala": "Scala", "lua": "Lua", "r": "R", "ex": "Elixir", "exs": "Elixir",
        "vue": "Vue", "svelte": "Svelte", "sol": "Solidity", "sql": "SQL", "sh": "Shell", "zsh": "Shell",
        "fish": "Shell", "html": "HTML", "css": "CSS", "scss": "CSS"
    ]

    private let documentExtensions: Set<String> = ["md", "markdown", "mdown", "rst", "txt", "adoc"]
    private let configExtensions: Set<String> = ["json", "jsonc", "yaml", "yml", "toml", "xml", "plist", "ini", "cfg", "gradle"]
    private let specialFiles: Set<String> = [
        "dockerfile", "makefile", "gemfile", "procfile", "justfile", "package.swift", "package.json",
        "cargo.toml", "pyproject.toml", "go.mod", "podfile", "composer.json", "requirements.txt"
    ]
    private let sensitiveExtensions: Set<String> = ["pem", "key", "p12", "pfx", "keystore", "mobileprovision"]
    private let sensitiveExactNames: Set<String> = [
        ".env", ".env.local", ".env.production", ".netrc", ".npmrc", ".pypirc", "id_rsa", "id_ed25519",
        "credentials", "credentials.json", "secrets.json", "secrets.yaml", "secrets.yml"
    ]

    func buildProfile(folders: [URL], repositoryCount: Int) -> BuilderProfile {
        var candidates: [Candidate] = []
        var technologyCounts: [String: Int] = [:]
        var kindCounts: [String: Int] = ["Code": 0, "Docs": 0, "Config": 0]
        var scannedFileCount = 0
        var testFileCount = 0

        for folder in folders {
            guard !Task.isCancelled else { break }
            let didAccess = folder.startAccessingSecurityScopedResource()
            defer { if didAccess { folder.stopAccessingSecurityScopedResource() } }
            inventory(
                folder: folder,
                candidates: &candidates,
                technologyCounts: &technologyCounts,
                kindCounts: &kindCounts,
                scannedFileCount: &scannedFileCount,
                testFileCount: &testFileCount
            )
        }

        let sample = diverseSample(from: candidates, limit: 420)
        var sampledText = ""
        sampledText.reserveCapacity(min(sample.count * 4_000, 2_000_000))
        var todoCount = 0
        var readableSampleCount = 0

        for candidate in sample {
            guard !Task.isCancelled else { break }
            guard let data = try? Data(contentsOf: candidate.url, options: [.mappedIfSafe]),
                  let text = String(data: data.prefix(48_000), encoding: .utf8) else { continue }
            readableSampleCount += 1
            let lowered = text.lowercased()
            todoCount += lowered.components(separatedBy: "todo").count - 1
            todoCount += lowered.components(separatedBy: "fixme").count - 1
            if sampledText.count < 2_000_000 {
                sampledText += "\n" + String(text.prefix(8_000))
            }
        }

        let technologies = technologyCounts
            .sorted { lhs, rhs in lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value }
            .prefix(8)
            .map { BuilderProfile.Technology(name: $0.key, fileCount: $0.value) }
        let technologyNames = technologies.map(\.name)
        let interests = TopicProfiler.topics(from: sampledText, manifestTags: technologyNames, limit: 10)
            .filter { !technologyNames.contains($0) }
        let opportunities = makeOpportunities(
            repositoryCount: repositoryCount,
            kindCounts: kindCounts,
            testFileCount: testFileCount,
            todoCount: todoCount,
            technologies: technologyNames,
            interests: interests
        )

        return BuilderProfile(
            scannedFileCount: scannedFileCount,
            sampledFileCount: readableSampleCount,
            repositoryCount: repositoryCount,
            technologies: technologies,
            interests: interests,
            opportunities: opportunities,
            fileKinds: kindCounts,
            updatedAt: Date()
        )
    }

    private func inventory(
        folder: URL,
        candidates: inout [Candidate],
        technologyCounts: inout [String: Int],
        kindCounts: inout [String: Int],
        scannedFileCount: inout Int,
        testFileCount: inout Int
    ) {
        let manager = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey, .fileSizeKey, .contentModificationDateKey]
        guard let enumerator = manager.enumerator(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [.skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return }

        while let url = enumerator.nextObject() as? URL {
            guard !Task.isCancelled else { break }
            let values = try? url.resourceValues(forKeys: Set(keys))
            if values?.isDirectory == true {
                if ignoredDirectories.contains(url.lastPathComponent) || url.lastPathComponent.hasPrefix(".") {
                    enumerator.skipDescendants()
                }
                continue
            }
            guard values?.isRegularFile == true, !isSensitive(url), (values?.fileSize ?? 0) <= 512_000 else { continue }

            let filename = url.lastPathComponent.lowercased()
            let ext = url.pathExtension.lowercased()
            let technology = technologyByExtension[ext]
            let kind: String
            if technology != nil {
                kind = "Code"
            } else if documentExtensions.contains(ext) || filename.hasPrefix("readme") {
                kind = "Docs"
            } else if configExtensions.contains(ext) || specialFiles.contains(filename) {
                kind = "Config"
            } else {
                continue
            }

            scannedFileCount += 1
            kindCounts[kind, default: 0] += 1
            if let technology { technologyCounts[technology, default: 0] += 1 }
            if filename.contains("test") || filename.contains("spec") || url.pathComponents.contains("Tests") || url.pathComponents.contains("__tests__") {
                testFileCount += 1
            }
            candidates.append(Candidate(
                url: url,
                kind: kind,
                technology: technology,
                score: samplingScore(for: url)
            ))
        }
    }

    private func diverseSample(from candidates: [Candidate], limit: Int) -> [Candidate] {
        var extensionCounts: [String: Int] = [:]
        var kindCounts: [String: Int] = [:]
        var result: [Candidate] = []

        for candidate in candidates.sorted(by: { $0.score > $1.score }) {
            let ext = candidate.url.pathExtension.lowercased().isEmpty ? candidate.url.lastPathComponent.lowercased() : candidate.url.pathExtension.lowercased()
            guard extensionCounts[ext, default: 0] < 42 else { continue }
            let kindLimit = candidate.kind == "Code" ? 300 : 90
            guard kindCounts[candidate.kind, default: 0] < kindLimit else { continue }
            result.append(candidate)
            extensionCounts[ext, default: 0] += 1
            kindCounts[candidate.kind, default: 0] += 1
            if result.count == limit { break }
        }
        return result
    }

    private func samplingScore(for url: URL) -> UInt64 {
        let day = Calendar(identifier: .gregorian).ordinality(of: .day, in: .year, for: Date()) ?? 1
        let value = url.path + "#\(day)"
        return value.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }

    private func isSensitive(_ url: URL) -> Bool {
        let filename = url.lastPathComponent.lowercased()
        let ext = url.pathExtension.lowercased()
        if sensitiveExactNames.contains(filename) || filename.hasPrefix(".env.") || sensitiveExtensions.contains(ext) {
            return true
        }
        if configExtensions.contains(ext) && (filename.contains("credential") || filename.contains("secret") || filename.contains("password")) {
            return true
        }
        return false
    }

    private func makeOpportunities(
        repositoryCount: Int,
        kindCounts: [String: Int],
        testFileCount: Int,
        todoCount: Int,
        technologies: [String],
        interests: [String]
    ) -> [BuilderProfile.Opportunity] {
        var result: [BuilderProfile.Opportunity] = []
        let codeCount = kindCounts["Code", default: 0]
        let docsCount = kindCounts["Docs", default: 0]

        if codeCount >= 15 && Double(testFileCount) / Double(max(codeCount, 1)) < 0.08 {
            result.append(.init(
                title: "Testing and confidence",
                reason: "Your sampled code has relatively few test files, so quality tools may have an outsized payoff.",
                searchTerm: "testing"
            ))
        }
        if todoCount >= 8 {
            result.append(.init(
                title: "Finishing active work",
                reason: "The sample contains recurring TODO or FIXME markers; automation and project-health tools could help close loops.",
                searchTerm: "automation"
            ))
        }
        if repositoryCount >= 5 {
            result.append(.init(
                title: "Navigate a growing code library",
                reason: "You have several local projects, so cross-repository search and maintenance tools should save time.",
                searchTerm: "code-search"
            ))
        }
        if codeCount >= 25 && Double(docsCount) / Double(max(codeCount, 1)) < 0.04 {
            result.append(.init(
                title: "Keep project knowledge visible",
                reason: "Your profile is code-heavy relative to documentation, making lightweight documentation tools a useful complement.",
                searchTerm: "documentation"
            ))
        }
        if interests.contains(where: { $0.localizedCaseInsensitiveContains("Local") }) {
            result.append(.init(
                title: "Lean into local-first software",
                reason: "Local-first patterns recur in the sampled files, so sync and embedded-data projects may fit your direction.",
                searchTerm: "local-first"
            ))
        }
        if result.isEmpty, let technology = technologies.first {
            result.append(.init(
                title: "Upgrade your \(technology) toolkit",
                reason: "\(technology) is prominent in your allowed folders, so mature tools and libraries for it are likely useful.",
                searchTerm: "developer-tool"
            ))
        }
        return Array(result.prefix(4))
    }
}
