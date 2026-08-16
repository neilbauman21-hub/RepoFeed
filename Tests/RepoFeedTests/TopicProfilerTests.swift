import Foundation
import Testing
@testable import RepoFeed

struct TopicProfilerTests {
    @Test func extractsHeadingAndSummary() {
        let markdown = """
        # Pocket Studio

        A local-first SwiftUI app for collecting small creative projects.

        ## Installation
        Run the package.
        """
        #expect(TopicProfiler.title(from: markdown, fallback: "fallback") == "Pocket Studio")
        #expect(TopicProfiler.summary(from: markdown, fallback: "fallback").hasPrefix("A local-first"))
    }

    @Test func prioritizesManifestTechnologies() {
        let topics = TopicProfiler.topics(
            from: "A React interface with a small local-first store.",
            manifestTags: ["TypeScript"]
        )
        #expect(topics.first == "TypeScript")
        #expect(topics.contains("React"))
    }

    @Test func normalizesGitHubSSHRemote() {
        let url = RepositoryScanner.normalizeGitRemote("git@github.com:octocat/Hello-World.git")
        #expect(url?.absoluteString == "https://github.com/octocat/Hello-World")
    }

    @Test func extractsGitHubFullName() {
        let url = URL(string: "https://github.com/octocat/Hello-World.git")!
        #expect(GitHubService.githubFullName(from: url) == "octocat/hello-world")
    }

    @Test func scansARepositoryFromAnAllowedFolder() async throws {
        let manager = FileManager.default
        let root = manager.temporaryDirectory.appendingPathComponent("repofeed-test-\(UUID().uuidString)")
        let repository = root.appendingPathComponent("tiny-studio")
        try manager.createDirectory(at: repository, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: root) }

        try "// swift-tools-version: 6.0".write(
            to: repository.appendingPathComponent("Package.swift"),
            atomically: true,
            encoding: .utf8
        )
        try "# Tiny Studio\n\nA local-first SwiftUI sketchbook.".write(
            to: repository.appendingPathComponent("README.md"),
            atomically: true,
            encoding: .utf8
        )

        let results = await RepositoryScanner().scan(folders: [root])
        #expect(results.count == 1)
        #expect(results.first?.title == "Tiny Studio")
        #expect(results.first?.topics.contains("Swift") == true)
    }

    @Test func buildsProfileWhileExcludingSensitiveFiles() async throws {
        let manager = FileManager.default
        let root = manager.temporaryDirectory.appendingPathComponent("repofeed-profile-\(UUID().uuidString)")
        let sources = root.appendingPathComponent("Sources")
        try manager.createDirectory(at: sources, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: root) }

        try "import SwiftUI\n// TODO: Add tests\nstruct HomeView: View {}".write(
            to: sources.appendingPathComponent("HomeView.swift"), atomically: true, encoding: .utf8
        )
        try "# Private sketchbook\n\nA local-first creative coding tool.".write(
            to: root.appendingPathComponent("README.md"), atomically: true, encoding: .utf8
        )
        try "API_KEY=must-never-be-read".write(
            to: root.appendingPathComponent(".env"), atomically: true, encoding: .utf8
        )

        let profile = await FileProfileScanner().buildProfile(folders: [root], repositoryCount: 1)
        #expect(profile.scannedFileCount == 2)
        #expect(profile.sampledFileCount == 2)
        #expect(profile.technologies.first?.name == "Swift")
        #expect(!profile.interests.contains("Must"))
    }
}
