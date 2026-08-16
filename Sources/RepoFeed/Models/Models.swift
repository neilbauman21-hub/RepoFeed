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

    struct LicenseInfo: Codable, Hashable, Sendable {
        let key: String?
        let name: String?
        let spdxID: String?

        enum CodingKeys: String, CodingKey {
            case key, name
            case spdxID = "spdx_id"
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
    let license: LicenseInfo?

    enum CodingKeys: String, CodingKey {
        case id, name, description, owner, language, topics
        case fullName = "full_name"
        case htmlURL = "html_url"
        case stars = "stargazers_count"
        case updatedAt = "updated_at"
        case license
    }

    var isOpenSource: Bool {
        OpenSourceLicensePolicy.allows(license?.spdxID ?? license?.key)
    }
}

struct GitHubSearchResponse: Decodable, Sendable {
    let items: [GitHubRepository]
}

enum DiscoveryMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case github = "GitHub"
    case huggingFace = "Hugging Face"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .github: "chevron.left.forwardslash.chevron.right"
        case .huggingFace: "face.smiling.inverse"
        }
    }
}

enum HuggingFaceArtifactKind: String, Codable, CaseIterable, Sendable {
    case model = "Model"
    case dataset = "Dataset"
    case space = "Space"
}

struct HuggingFaceArtifact: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let author: String?
    let kind: HuggingFaceArtifactKind
    let downloads: Int
    let likes: Int
    let pipelineTag: String?
    let tags: [String]
    let sdk: String?
    let createdAt: Date?
    let lastModified: Date?
    let trendingScore: Int

    var url: URL {
        switch kind {
        case .model: URL(string: "https://huggingface.co/\(id)")!
        case .dataset: URL(string: "https://huggingface.co/datasets/\(id)")!
        case .space: URL(string: "https://huggingface.co/spaces/\(id)")!
        }
    }

    var licenseID: String? {
        tags.first(where: { $0.lowercased().hasPrefix("license:") })
            .map { String($0.dropFirst("license:".count)) }
    }

    var isOpenSource: Bool { OpenSourceLicensePolicy.allows(licenseID) }

    var displayTask: String {
        pipelineTag ?? sdk ?? tags.first(where: {
            !$0.contains(":") && !["transformers", "safetensors", "pytorch", "region"].contains($0.lowercased())
        }) ?? kind.rawValue
    }
}

struct HuggingFaceArtifactResponse: Decodable, Sendable {
    let id: String
    let author: String?
    let downloads: Int?
    let likes: Int?
    let pipelineTag: String?
    let tags: [String]?
    let sdk: String?
    let privateRepo: Bool?
    let gated: Bool
    let createdAt: Date?
    let lastModified: Date?
    let trendingScore: Int?

    enum CodingKeys: String, CodingKey {
        case id, author, downloads, likes, tags, sdk, gated, createdAt, lastModified, trendingScore
        case pipelineTag = "pipeline_tag"
        case privateRepo = "private"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        downloads = try container.decodeIfPresent(Int.self, forKey: .downloads)
        likes = try container.decodeIfPresent(Int.self, forKey: .likes)
        pipelineTag = try container.decodeIfPresent(String.self, forKey: .pipelineTag)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        sdk = try container.decodeIfPresent(String.self, forKey: .sdk)
        privateRepo = try container.decodeIfPresent(Bool.self, forKey: .privateRepo)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified)
        trendingScore = try container.decodeIfPresent(Int.self, forKey: .trendingScore)
        if let value = try? container.decode(Bool.self, forKey: .gated) {
            gated = value
        } else if let value = try? container.decode(String.self, forKey: .gated) {
            gated = !value.isEmpty
        } else {
            gated = false
        }
    }

    func artifact(kind: HuggingFaceArtifactKind) -> HuggingFaceArtifact {
        HuggingFaceArtifact(
            id: id,
            author: author,
            kind: kind,
            downloads: downloads ?? 0,
            likes: likes ?? 0,
            pipelineTag: pipelineTag,
            tags: tags ?? [],
            sdk: sdk,
            createdAt: createdAt,
            lastModified: lastModified,
            trendingScore: trendingScore ?? 0
        )
    }
}

enum OpenSourceLicensePolicy {
    private static let allowed: Set<String> = [
        "0bsd", "afl-3.0", "agpl-3.0", "apache-2.0", "artistic-2.0", "bsd", "bsd-2-clause",
        "bsd-3-clause", "bsl-1.0", "cc-by-3.0", "cc-by-4.0", "cc0-1.0", "ecl-2.0", "epl-1.0",
        "epl-2.0", "eupl-1.1", "eupl-1.2", "gpl-2.0", "gpl-3.0", "isc", "lgpl-2.1", "lgpl-3.0",
        "mit", "mpl-2.0", "ms-pl", "ms-rl", "mulanpsl-2.0", "ncsa", "odbl", "odc-by", "ofl-1.1",
        "pddl", "postgresql", "psf-2.0", "unlicense", "wtfpl", "zlib"
    ]

    static func allows(_ identifier: String?) -> Bool {
        guard let identifier else { return false }
        let normalized = identifier.lowercased()
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: "+", with: "")
        return allowed.contains(normalized)
    }
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
