import Foundation

struct LocalRepository: Identifiable, Codable, Hashable, Sendable {
    var id: String { directoryURL.path }
    let name: String
    let title: String
    let summary: String
    let readmePreview: String
    let directoryURL: URL
    let readmeURL: URL
    let remoteURL: URL?
    let topics: [String]
    let languages: [String]
    let modifiedAt: Date
}

struct BuilderProfile: Codable, Hashable, Sendable {
    struct Technology: Identifiable, Codable, Hashable, Sendable {
        var id: String { name }
        let name: String
        let fileCount: Int
    }

    struct Opportunity: Identifiable, Codable, Hashable, Sendable {
        var id: String { title }
        let title: String
        let reason: String
        let searchTerm: String
    }

    let scannedFileCount: Int
    let sampledFileCount: Int
    let repositoryCount: Int
    let technologies: [Technology]
    let interests: [String]
    let opportunities: [Opportunity]
    let fileKinds: [String: Int]
    let updatedAt: Date

    static let empty = BuilderProfile(
        scannedFileCount: 0,
        sampledFileCount: 0,
        repositoryCount: 0,
        technologies: [],
        interests: [],
        opportunities: [],
        fileKinds: [:],
        updatedAt: .distantPast
    )

    var headline: String {
        let names = technologies.prefix(3).map(\.name)
        guard !names.isEmpty else { return "Your builder profile is taking shape" }
        if names.count == 1 { return "You’re building mostly with \(names[0])" }
        if names.count == 2 { return "You’re building with \(names[0]) and \(names[1])" }
        return "You’re building with \(names[0]), \(names[1]), and \(names[2])"
    }

    var recommendationTerms: [String] {
        var terms = technologies.prefix(3).map(\.name)
        terms.append(contentsOf: opportunities.prefix(2).map(\.searchTerm))
        return Array(NSOrderedSet(array: terms).compactMap { $0 as? String })
    }
}

struct ScanResult: Sendable {
    let repositories: [LocalRepository]
    let profile: BuilderProfile
}

struct GitHubRepository: Identifiable, Codable, Hashable, Sendable {
    struct Owner: Codable, Hashable, Sendable {
        let login: String
        let avatarURL: URL?

        enum CodingKeys: String, CodingKey {
            case login
            case avatarURL = "avatar_url"
        }
    }

    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let htmlURL: URL
    let owner: Owner
    let stars: Int
    let language: String?
    let topics: [String]
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, owner, language, topics
        case fullName = "full_name"
        case htmlURL = "html_url"
        case stars = "stargazers_count"
        case updatedAt = "updated_at"
    }
}

struct GitHubSearchResponse: Decodable, Sendable {
    let items: [GitHubRepository]
}

struct AllowedFolder: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var displayName: String
    var displayPath: String
    var bookmark: Data
}

enum FeedDestination: String, CaseIterable, Identifiable {
    case feed = "Your Feed"
    case library = "Local Library"
    case discover = "Discover"
    case permissions = "Permissions"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .feed: "rectangle.stack.fill"
        case .library: "books.vertical.fill"
        case .discover: "sparkles"
        case .permissions: "hand.raised.fill"
        }
    }
}
