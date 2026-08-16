import Foundation

enum GitHubServiceError: LocalizedError {
    case invalidRequest
    case rateLimited(resetDate: Date?)
    case server(statusCode: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidRequest: "RepoFeed could not build the GitHub search."
        case .rateLimited(let resetDate):
            if let resetDate {
                "GitHub's public search limit was reached. Try again after \(resetDate.formatted(date: .omitted, time: .shortened))."
            } else {
                "GitHub's public search limit was reached. Try again in a few minutes."
            }
        case .server(let statusCode): "GitHub returned an error (HTTP \(statusCode))."
        case .invalidResponse: "GitHub returned data RepoFeed could not read."
        }
    }
}

struct GitHubService: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func recommendations(for profile: BuilderProfile, excluding remoteURLs: [URL]) async throws -> [GitHubRepository] {
        let skills = profile.technologies.prefix(2).map { Self.searchTerm($0.name) }.filter { !$0.isEmpty }
        let opportunity = profile.opportunities.first.map { Self.searchTerm($0.searchTerm) }
        let fallback = profile.interests.prefix(2).map(Self.searchTerm).filter { !$0.isEmpty }
        guard let primary = skills.first ?? fallback.first else { return [] }

        let primaryQuery = "\(primary) tool in:name,description,readme stars:>40 archived:false"
        let benefit = opportunity ?? skills.dropFirst().first ?? "developer-tool"
        let benefitQuery = "\(primary) \(benefit) in:name,description,readme stars:>15 archived:false"
        async let primaryResults = search(query: primaryQuery, sort: "stars", order: "desc", perPage: 50)
        async let benefitResults = search(query: benefitQuery, sort: "stars", order: "desc", perPage: 50)
        let combined = (try await primaryResults) + (try await benefitResults)

        let excludedNames = Set(remoteURLs.compactMap(Self.githubFullName))
        var unique: [Int: GitHubRepository] = [:]
        for repository in combined where repository.isOpenSource && !excludedNames.contains(repository.fullName.lowercased()) {
            unique[repository.id] = repository
        }
        return Array(unique.values.sorted {
            benefitScore($0, profile: profile) > benefitScore($1, profile: profile)
        }.prefix(12))
    }

    func trending() async throws -> [GitHubRepository] {
        let calendar = Calendar(identifier: .gregorian)
        let threshold = calendar.date(byAdding: .day, value: -45, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let query = "created:>=\(formatter.string(from: threshold)) stars:>15 archived:false"
        return Array(try await search(query: query, sort: "stars", order: "desc", perPage: 50).filter(\.isOpenSource).prefix(8))
    }

    private func search(query: String, sort: String, order: String, perPage: Int) async throws -> [GitHubRepository] {
        var components = URLComponents(string: "https://api.github.com/search/repositories")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sort", value: sort),
            URLQueryItem(name: "order", value: order),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        guard let url = components?.url else { throw GitHubServiceError.invalidRequest }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("RepoFeed/0.1", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GitHubServiceError.invalidResponse }
        if http.statusCode == 403 || http.statusCode == 429 {
            let reset = http.value(forHTTPHeaderField: "x-ratelimit-reset").flatMap(TimeInterval.init).map(Date.init(timeIntervalSince1970:))
            throw GitHubServiceError.rateLimited(resetDate: reset)
        }
        guard (200..<300).contains(http.statusCode) else { throw GitHubServiceError.server(statusCode: http.statusCode) }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode(GitHubSearchResponse.self, from: data) else {
            throw GitHubServiceError.invalidResponse
        }
        return decoded.items
    }

    static func searchTerm(_ value: String) -> String {
        value.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    static func githubFullName(from url: URL) -> String? {
        guard url.host?.lowercased() == "github.com" else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2 else { return nil }
        return "\(parts[0])/\(parts[1].replacingOccurrences(of: ".git", with: ""))".lowercased()
    }

    private func benefitScore(_ repository: GitHubRepository, profile: BuilderProfile) -> Double {
        let haystack = ([repository.name, repository.description ?? "", repository.language ?? ""] + repository.topics)
            .joined(separator: " ")
            .lowercased()
        var score = log10(Double(max(repository.stars, 1))) * 2
        for (index, technology) in profile.technologies.enumerated() where haystack.contains(technology.name.lowercased()) {
            score += Double(max(2, 8 - index))
        }
        for opportunity in profile.opportunities {
            let tokens = opportunity.searchTerm.lowercased().split(separator: "-").map(String.init)
            if tokens.contains(where: haystack.contains) { score += 7 }
        }
        let benefitWords = ["tool", "test", "debug", "lint", "search", "docs", "monitor", "local", "database", "cli", "automation"]
        score += Double(benefitWords.filter(haystack.contains).count) * 1.4
        return score
    }
}
