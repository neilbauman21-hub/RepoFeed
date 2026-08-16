import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var destination: FeedDestination = .feed
    @Published var localRepositories: [LocalRepository] = []
    @Published var builderProfile: BuilderProfile = .empty
    @Published var recommendations: [GitHubRepository] = []
    @Published var trendingRepositories: [GitHubRepository] = []
    @Published var huggingFaceRecommendations: [HuggingFaceArtifact] = []
    @Published var huggingFaceTrending: [HuggingFaceArtifact] = []
    @Published var discoveryMode: DiscoveryMode = .github {
        didSet { UserDefaults.standard.set(discoveryMode.rawValue, forKey: "repofeed.discovery-mode") }
    }
    @Published var allowedFolders: [AllowedFolder] = []
    @Published var isRefreshing = false
    @Published var statusMessage = "Choose a folder to create your feed."
    @Published var errorMessage: String?
    @Published var searchText = ""

    private let folderStore: FolderAccessStore
    private let scanner = RepositoryScanner()
    private let profileScanner = FileProfileScanner()
    private let github = GitHubService()
    private let huggingFace = HuggingFaceService()
    private var refreshTask: Task<Void, Never>?

    init(folderStore: FolderAccessStore = FolderAccessStore()) {
        self.folderStore = folderStore
        allowedFolders = folderStore.folders
        if !allowedFolders.isEmpty {
            statusMessage = "Preparing your private profile…"
        }
        if let savedMode = UserDefaults.standard.string(forKey: "repofeed.discovery-mode"),
           let mode = DiscoveryMode(rawValue: savedMode) {
            discoveryMode = mode
        }
        loadCache()

        Task { [weak self] in
            guard let self else { return }
            if self.allowedFolders.isEmpty {
                await self.refreshTrendingOnly()
            } else {
                await self.refresh()
            }
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    var visibleLocalRepositories: [LocalRepository] {
        guard !searchText.isEmpty else { return localRepositories }
        return localRepositories.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.summary.localizedCaseInsensitiveContains(searchText) ||
            $0.topics.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var interestProfile: [String] {
        let technologies = builderProfile.technologies.prefix(5).map(\.name)
        let interests = builderProfile.interests.prefix(5)
        return Array(NSOrderedSet(array: technologies + interests).compactMap { $0 as? String }).prefix(8).map { $0 }
    }

    func chooseFolders() {
        let panel = NSOpenPanel()
        panel.title = "Allow RepoFeed to scan folders"
        panel.message = "RepoFeed inventories safe files and locally samples code, docs, and configs inside only the folders you select."
        panel.prompt = "Allow Access"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false

        guard panel.runModal() == .OK else { return }
        do {
            try folderStore.add(panel.urls)
            allowedFolders = folderStore.folders
            Task { await refresh() }
        } catch {
            errorMessage = "RepoFeed could not remember that folder: \(error.localizedDescription)"
        }
    }

    func removeFolder(_ folder: AllowedFolder) {
        folderStore.remove(id: folder.id)
        allowedFolders = folderStore.folders
        Task { await refresh() }
    }

    func requestRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in await self?.refresh() }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil
        statusMessage = "Scanning the folders you allowed…"

        let folders = folderStore.resolveFolders()
        allowedFolders = folderStore.folders
        let scanned = await scanner.scan(folders: folders)
        guard !Task.isCancelled else { isRefreshing = false; return }
        localRepositories = scanned
        builderProfile = await profileScanner.buildProfile(folders: folders, repositoryCount: scanned.count)
        statusMessage = builderProfile.scannedFileCount == 0
            ? "No safe code or document files found yet."
            : "Inventoried \(builderProfile.scannedFileCount) files and sampled \(builderProfile.sampledFileCount) locally."

        let remotes = scanned.compactMap(\.remoteURL)
        do {
            async let recommended = github.recommendations(for: builderProfile, excluding: remotes)
            async let trending = github.trending()
            let (newRecommendations, newTrending) = try await (recommended, trending)
            recommendations = newRecommendations
            trendingRepositories = newTrending
            saveCache()
        } catch {
            errorMessage = error.localizedDescription
        }
        do {
            async let recommended = huggingFace.recommendations(for: builderProfile)
            async let trending = huggingFace.trending()
            let (newRecommendations, newTrending) = try await (recommended, trending)
            huggingFaceRecommendations = newRecommendations
            huggingFaceTrending = newTrending
            saveCache()
        } catch {
            if errorMessage == nil { errorMessage = error.localizedDescription }
        }
        isRefreshing = false
    }

    func refreshTrendingOnly() async {
        guard trendingRepositories.isEmpty || huggingFaceTrending.isEmpty else { return }
        do {
            async let githubTrending = github.trending()
            async let hubTrending = huggingFace.trending()
            let (newGitHub, newHub) = try await (githubTrending, hubTrending)
            trendingRepositories = newGitHub
            huggingFaceTrending = newHub
            saveCache()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func recommendationReason(for repository: GitHubRepository) -> String {
        let haystack = ([repository.name, repository.description ?? "", repository.language ?? ""] + repository.topics)
            .joined(separator: " ")
            .lowercased()
        if let opportunity = builderProfile.opportunities.first(where: {
            let tokens = $0.searchTerm.lowercased().split(separator: "-").map(String.init)
            return tokens.contains(where: haystack.contains)
        }) {
            return "\(opportunity.title): \(opportunity.reason)"
        }
        if let technology = builderProfile.technologies.first(where: {
            haystack.contains($0.name.lowercased())
        }) {
            return "Useful alongside the \(technology.name) work found in your allowed folders."
        }
        if let interest = builderProfile.interests.first(where: { haystack.contains($0.lowercased()) }) {
            return "Connects to your recurring interest in \(interest.lowercased())."
        }
        return "A well-supported developer tool that complements your current mix of projects."
    }

    func recommendationReason(for artifact: HuggingFaceArtifact) -> String {
        let haystack = ([artifact.id, artifact.pipelineTag ?? "", artifact.sdk ?? ""] + artifact.tags)
            .joined(separator: " ").lowercased()
        if let opportunity = builderProfile.opportunities.first(where: {
            $0.searchTerm.lowercased().split(separator: "-").map(String.init).contains(where: haystack.contains)
        }) {
            return "\(opportunity.title): this \(artifact.kind.rawValue.lowercased()) matches that local profile signal."
        }
        if haystack.contains("code") {
            return "Could support the code-heavy projects detected in your allowed folders."
        }
        if haystack.contains("embedding") {
            return "Could add local semantic search without requiring RepoFeed to run a server."
        }
        return "An explicitly open-licensed \(artifact.kind.rawValue.lowercased()) related to your private builder profile."
    }

    private func loadCache() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "repofeed.builder-profile"),
           let cached = try? decoder.decode(BuilderProfile.self, from: data) {
            builderProfile = cached
        }
        if let data = UserDefaults.standard.data(forKey: "repofeed.github.recommendations"),
           let cached = try? decoder.decode([GitHubRepository].self, from: data) {
            recommendations = cached
        }
        if let data = UserDefaults.standard.data(forKey: "repofeed.github.trending"),
           let cached = try? decoder.decode([GitHubRepository].self, from: data) {
            trendingRepositories = cached
        }
        if let data = UserDefaults.standard.data(forKey: "repofeed.huggingface.recommendations"),
           let cached = try? decoder.decode([HuggingFaceArtifact].self, from: data) {
            huggingFaceRecommendations = cached
        }
        if let data = UserDefaults.standard.data(forKey: "repofeed.huggingface.trending"),
           let cached = try? decoder.decode([HuggingFaceArtifact].self, from: data) {
            huggingFaceTrending = cached
        }
    }

    private func saveCache() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(builderProfile) {
            UserDefaults.standard.set(data, forKey: "repofeed.builder-profile")
        }
        if let data = try? encoder.encode(recommendations) {
            UserDefaults.standard.set(data, forKey: "repofeed.github.recommendations")
        }
        if let data = try? encoder.encode(trendingRepositories) {
            UserDefaults.standard.set(data, forKey: "repofeed.github.trending")
        }
        if let data = try? encoder.encode(huggingFaceRecommendations) {
            UserDefaults.standard.set(data, forKey: "repofeed.huggingface.recommendations")
        }
        if let data = try? encoder.encode(huggingFaceTrending) {
            UserDefaults.standard.set(data, forKey: "repofeed.huggingface.trending")
        }
    }
}
