import Foundation

actor RepositoryScanner {
    private let ignoredDirectories: Set<String> = [
        ".git", ".build", ".next", ".venv", "build", "dist", "DerivedData", "node_modules",
        "Pods", "target", "vendor", "venv"
    ]
    private let readmeExtensions: Set<String> = ["", "md", "markdown", "mdown", "txt", "rst"]

    func scan(folders: [URL]) -> [LocalRepository] {
        var repositories: [LocalRepository] = []
        var seenPaths = Set<String>()

        for folder in folders {
            guard !Task.isCancelled else { break }
            let didAccess = folder.startAccessingSecurityScopedResource()
            defer { if didAccess { folder.stopAccessingSecurityScopedResource() } }
            repositories.append(contentsOf: scan(folder: folder, seenPaths: &seenPaths))
        }

        return repositories.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    private func scan(folder: URL, seenPaths: inout Set<String>) -> [LocalRepository] {
        let manager = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey, .contentModificationDateKey]
        guard let enumerator = manager.enumerator(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [.skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return [] }

        var results: [LocalRepository] = []
        while let item = enumerator.nextObject() as? URL, results.count < 300 {
            guard !Task.isCancelled else { break }
            let values = try? item.resourceValues(forKeys: Set(keys))

            if values?.isDirectory == true {
                if ignoredDirectories.contains(item.lastPathComponent) || item.lastPathComponent.hasPrefix(".") {
                    enumerator.skipDescendants()
                }
                continue
            }

            let filename = item.lastPathComponent.lowercased()
            guard filename.hasPrefix("readme"), readmeExtensions.contains(item.pathExtension.lowercased()) else { continue }

            let directory = item.deletingLastPathComponent().standardizedFileURL
            guard !seenPaths.contains(directory.path), looksLikeRepository(directory, manager: manager) else { continue }
            seenPaths.insert(directory.path)

            guard let data = try? Data(contentsOf: item, options: [.mappedIfSafe]), data.count <= 1_500_000,
                  let markdown = String(data: data, encoding: .utf8) else { continue }

            let manifestTags = inferManifestTags(at: directory, manager: manager)
            let languages = inferLanguages(from: manifestTags)
            let fallback = directory.lastPathComponent
            let modifiedAt = values?.contentModificationDate ?? (try? directory.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast

            results.append(LocalRepository(
                name: fallback,
                title: TopicProfiler.title(from: markdown, fallback: fallback),
                summary: TopicProfiler.summary(from: markdown, fallback: fallback),
                readmePreview: TopicProfiler.cleanPreview(markdown),
                directoryURL: directory,
                readmeURL: item,
                remoteURL: gitRemoteURL(at: directory, manager: manager),
                topics: TopicProfiler.topics(from: markdown, manifestTags: manifestTags),
                languages: languages,
                modifiedAt: modifiedAt
            ))
        }
        return results
    }

    private func looksLikeRepository(_ directory: URL, manager: FileManager) -> Bool {
        let signals = [".git", "Package.swift", "package.json", "Cargo.toml", "pyproject.toml", "go.mod", "Gemfile", "pom.xml", "build.gradle", "composer.json"]
        return signals.contains { manager.fileExists(atPath: directory.appendingPathComponent($0).path) }
    }

    private func inferManifestTags(at directory: URL, manager: FileManager) -> [String] {
        let manifests: [(String, String)] = [
            ("Package.swift", "Swift"), ("package.json", "JavaScript"), ("tsconfig.json", "TypeScript"),
            ("Cargo.toml", "Rust"), ("pyproject.toml", "Python"), ("requirements.txt", "Python"),
            ("go.mod", "Go"), ("Gemfile", "Ruby"), ("pom.xml", "Java"), ("build.gradle", "Kotlin"),
            ("Dockerfile", "Docker")
        ]
        return Array(Set(manifests.compactMap { filename, tag in
            manager.fileExists(atPath: directory.appendingPathComponent(filename).path) ? tag : nil
        })).sorted()
    }

    private func inferLanguages(from tags: [String]) -> [String] {
        let excluded = Set(["Docker"])
        return tags.filter { !excluded.contains($0) }
    }

    private func gitRemoteURL(at directory: URL, manager: FileManager) -> URL? {
        let configURL = directory.appendingPathComponent(".git/config")
        guard manager.fileExists(atPath: configURL.path),
              let config = try? String(contentsOf: configURL, encoding: .utf8) else { return nil }

        for rawLine in config.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("url = ") else { continue }
            return Self.normalizeGitRemote(String(line.dropFirst(6)))
        }
        return nil
    }

    static func normalizeGitRemote(_ rawValue: String) -> URL? {
        var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("git@github.com:") {
            value = "https://github.com/" + value.dropFirst("git@github.com:".count)
        } else if value.hasPrefix("ssh://git@github.com/") {
            value = "https://github.com/" + value.dropFirst("ssh://git@github.com/".count)
        }
        if value.hasSuffix(".git") { value.removeLast(4) }
        guard let url = URL(string: value), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }
}
