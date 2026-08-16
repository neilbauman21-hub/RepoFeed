import Foundation

enum HuggingFaceServiceError: LocalizedError {
    case invalidRequest
    case server(statusCode: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidRequest: "RepoFeed could not build the Hugging Face request."
        case .server(let statusCode): "Hugging Face returned an error (HTTP \(statusCode))."
        case .invalidResponse: "Hugging Face returned data RepoFeed could not read."
        }
    }
}

struct HuggingFaceService: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func recommendations(for profile: BuilderProfile) async throws -> [HuggingFaceArtifact] {
        let search = recommendationSearch(for: profile)
        async let models = list(kind: .model, search: search, sort: "downloads", limit: 50)
        async let datasets = list(kind: .dataset, search: search == "code" ? nil : search, sort: "downloads", limit: 35)
        let combined = (try await models) + (try await datasets)
        return Array(combined
            .filter(\.isOpenSource)
            .sorted { benefitScore($0, profile: profile) > benefitScore($1, profile: profile) }
            .prefix(14))
    }

    func trending() async throws -> [HuggingFaceArtifact] {
        async let models = list(kind: .model, search: nil, sort: "trendingScore", limit: 50)
        async let datasets = list(kind: .dataset, search: nil, sort: "trendingScore", limit: 35)
        async let spaces = list(kind: .space, search: nil, sort: "trendingScore", limit: 50)
        let combined = (try await models) + (try await datasets) + (try await spaces)
        return Array(combined
            .filter(\.isOpenSource)
            .sorted { lhs, rhs in
                lhs.trendingScore == rhs.trendingScore ? lhs.likes > rhs.likes : lhs.trendingScore > rhs.trendingScore
            }
            .prefix(10))
    }

    private func list(
        kind: HuggingFaceArtifactKind,
        search: String?,
        sort: String,
        limit: Int
    ) async throws -> [HuggingFaceArtifact] {
        let path: String
        switch kind {
        case .model: path = "models"
        case .dataset: path = "datasets"
        case .space: path = "spaces"
        }
        var components = URLComponents(string: "https://huggingface.co/api/\(path)")
        var items = [
            URLQueryItem(name: "sort", value: sort),
            URLQueryItem(name: "direction", value: "-1"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "full", value: "true")
        ]
        if let search, !search.isEmpty { items.append(URLQueryItem(name: "search", value: search)) }
        components?.queryItems = items
        guard let url = components?.url else { throw HuggingFaceServiceError.invalidRequest }

        var request = URLRequest(url: url)
        request.setValue("RepoFeed/0.2 (no-server desktop client)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw HuggingFaceServiceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw HuggingFaceServiceError.server(statusCode: http.statusCode) }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([HuggingFaceArtifactResponse].self, from: data) else {
            throw HuggingFaceServiceError.invalidResponse
        }
        return decoded
            .filter { $0.privateRepo != true && !$0.gated }
            .map { $0.artifact(kind: kind) }
    }

    private func recommendationSearch(for profile: BuilderProfile) -> String {
        let interests = (profile.interests + profile.opportunities.map(\.searchTerm)).joined(separator: " ").lowercased()
        if interests.contains("image") || interests.contains("vision") { return "image" }
        if interests.contains("audio") || interests.contains("voice") || interests.contains("speech") { return "audio" }
        if interests.contains("embedding") || interests.contains("search") { return "embedding" }
        if interests.contains("document") || interests.contains("text") { return "text" }
        return "code"
    }

    private func benefitScore(_ artifact: HuggingFaceArtifact, profile: BuilderProfile) -> Double {
        let haystack = ([artifact.id, artifact.pipelineTag ?? "", artifact.sdk ?? ""] + artifact.tags)
            .joined(separator: " ").lowercased()
        var score = log10(Double(max(artifact.downloads, 1))) * 2 + log10(Double(max(artifact.likes, 1)))
        for interest in profile.interests where haystack.contains(interest.lowercased()) { score += 5 }
        for opportunity in profile.opportunities {
            let tokens = opportunity.searchTerm.lowercased().split(separator: "-").map(String.init)
            if tokens.contains(where: haystack.contains) { score += 6 }
        }
        if haystack.contains("code") || haystack.contains("embedding") { score += 3 }
        if artifact.kind == .model && artifact.tags.contains(where: { $0 == "safetensors" }) { score += 1 }
        return score
    }
}
