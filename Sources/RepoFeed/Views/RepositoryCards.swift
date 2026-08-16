import SwiftUI

struct LocalRepositoryCard: View {
    let repository: LocalRepository
    @ObservedObject var model: AppModel
    @State private var showsReadme = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                RepoMark(seed: repository.id)
                VStack(alignment: .leading, spacing: 3) {
                    Text(repository.title)
                        .font(.headline.weight(.bold))
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Text("Local project")
                        Text("·")
                        Text(repository.modifiedAt, style: .relative)
                        Text("·")
                        Image(systemName: "lock.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(RepoFeedTheme.muted)
                }
                Spacer()
                Menu {
                    Button("Show in Finder", systemImage: "folder") { model.reveal(repository.directoryURL) }
                    Button("Open README", systemImage: "doc.text") { model.open(repository.readmeURL) }
                    if let remoteURL = repository.remoteURL {
                        Divider()
                        Button("Open remote", systemImage: "arrow.up.right.square") { model.open(remoteURL) }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(RepoFeedTheme.muted)
                        .frame(width: 28, height: 28)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
            }
            .padding(20)

            VStack(alignment: .leading, spacing: 14) {
                Text(repository.summary)
                    .font(.body)
                    .foregroundStyle(Color.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)

                if !repository.topics.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(repository.topics.prefix(6), id: \.self) { TopicPill(text: $0) }
                        }
                    }
                }

                if showsReadme {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(repository.readmeURL.lastPathComponent, systemImage: "doc.text.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RepoFeedTheme.primary)
                            Spacer()
                            Text("Preview")
                                .font(.caption2)
                                .foregroundStyle(RepoFeedTheme.muted)
                        }
                        ScrollView {
                            Text(repository.readmePreview)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.76))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 260)
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)

            HStack {
                HStack(spacing: -4) {
                    ReactionBubble(icon: "hand.thumbsup.fill", color: RepoFeedTheme.primary)
                    ReactionBubble(icon: "sparkles", color: RepoFeedTheme.secondary)
                }
                Text(repository.topics.prefix(2).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(RepoFeedTheme.muted)
                Spacer()
                Text("README available")
                    .font(.caption)
                    .foregroundStyle(RepoFeedTheme.muted)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            Divider().overlay(RepoFeedTheme.border)
            HStack(spacing: 4) {
                CardAction(title: showsReadme ? "Hide README" : "Read README", icon: "doc.richtext") {
                    withAnimation(.easeInOut(duration: 0.2)) { showsReadme.toggle() }
                }
                CardAction(title: "Open folder", icon: "folder") { model.reveal(repository.directoryURL) }
                if let remoteURL = repository.remoteURL {
                    CardAction(title: "View repo", icon: "arrow.up.right.square") { model.open(remoteURL) }
                }
            }
            .padding(8)
        }
        .repoCard()
    }
}

private struct ReactionBubble: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            Circle().fill(color)
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 18, height: 18)
        .overlay { Circle().stroke(RepoFeedTheme.card, lineWidth: 2) }
    }
}

private struct CardAction: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RepoFeedTheme.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.white.opacity(0.001), in: RoundedRectangle(cornerRadius: 9))
    }
}

struct SuggestedRepositoryPost: View {
    let repository: GitHubRepository
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 11) {
                ZStack {
                    Circle().fill(RepoFeedTheme.primary)
                    Text("r").font(.title2.weight(.black)).foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text("RepoFeed suggested a repository")
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 5) {
                        Text("Personalized for you")
                        Text("·")
                        Image(systemName: "lock.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(RepoFeedTheme.muted)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(RepoFeedTheme.muted)
                    .padding(6)
            }
            .padding(16)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    RepoMark(seed: repository.fullName, size: 54)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(repository.fullName)
                            .font(.title3.weight(.bold))
                        HStack(spacing: 10) {
                            Label(compactCount(repository.stars), systemImage: "star.fill")
                            if let language = repository.language {
                                Label(language, systemImage: "circle.fill")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(RepoFeedTheme.muted)
                    }
                }

                Text(repository.description ?? "A public repository selected for your builder profile.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                if !repository.topics.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(repository.topics.prefix(6), id: \.self) { TopicPill(text: $0) }
                        }
                    }
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color(hex: 0xF7B928))
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Why this may help")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RepoFeedTheme.primary)
                        Text(model.recommendationReason(for: repository))
                            .font(.subheadline)
                            .foregroundStyle(RepoFeedTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(13)
                .background(Color(hex: 0x3A3B3C), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)

            HStack {
                HStack(spacing: -4) {
                    ReactionBubble(icon: "hand.thumbsup.fill", color: RepoFeedTheme.primary)
                    ReactionBubble(icon: "star.fill", color: Color(hex: 0xF7B928))
                }
                Text("Recommended from your profile")
                    .font(.caption)
                    .foregroundStyle(RepoFeedTheme.muted)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 10)

            Divider().overlay(RepoFeedTheme.border)
            HStack(spacing: 0) {
                CardAction(title: "Open GitHub", icon: "arrow.up.right.square") { model.open(repository.htmlURL) }
                CardAction(title: "View profile", icon: "person.text.rectangle") { model.destination = .discover }
                CardAction(title: "Refresh", icon: "arrow.clockwise") { model.requestRefresh() }
            }
            .padding(8)
        }
        .repoCard()
    }
}

struct HuggingFaceArtifactPost: View {
    let artifact: HuggingFaceArtifact
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 11) {
                HubMark(size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text("RepoFeed found an OSS \(artifact.kind.rawValue.lowercased())")
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 5) {
                        Text("Direct from Hugging Face")
                        Text("·")
                        Image(systemName: "lock.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(RepoFeedTheme.muted)
                }
                Spacer()
                TopicPill(text: artifact.licenseID?.uppercased() ?? "OSS", tint: RepoFeedTheme.secondary)
            }
            .padding(16)

            VStack(alignment: .leading, spacing: 14) {
                Text(artifact.id)
                    .font(.title3.weight(.bold))
                    .textSelection(.enabled)
                HStack(spacing: 14) {
                    Label(artifact.kind.rawValue, systemImage: artifact.kind == .model ? "cpu" : artifact.kind == .dataset ? "tablecells" : "sparkles.rectangle.stack")
                    Label(artifact.displayTask, systemImage: "tag.fill")
                    if artifact.downloads > 0 { Label(compactCount(artifact.downloads), systemImage: "arrow.down.circle.fill") }
                    Label(compactCount(artifact.likes), systemImage: "heart.fill")
                }
                .font(.caption)
                .foregroundStyle(RepoFeedTheme.muted)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color(hex: 0xF7B928))
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Why this may help")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RepoFeedTheme.primary)
                        Text(model.recommendationReason(for: artifact))
                            .font(.subheadline)
                            .foregroundStyle(RepoFeedTheme.muted)
                    }
                }
                .padding(13)
                .background(Color(hex: 0x3A3B3C), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)

            Divider().overlay(RepoFeedTheme.border)
            HStack(spacing: 0) {
                CardAction(title: "Open on Hub", icon: "arrow.up.right.square") { model.open(artifact.url) }
                CardAction(title: artifact.licenseID?.uppercased() ?? "Open license", icon: "checkmark.seal") { model.open(artifact.url) }
                CardAction(title: "Refresh", icon: "arrow.clockwise") { model.requestRefresh() }
            }
            .padding(8)
        }
        .repoCard()
    }
}

struct HuggingFaceArtifactCard: View {
    let artifact: HuggingFaceArtifact
    @ObservedObject var model: AppModel

    var body: some View {
        Button { model.open(artifact.url) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HubMark(size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(artifact.kind.rawValue).font(.caption).foregroundStyle(RepoFeedTheme.muted)
                        Text(artifact.id).font(.headline.weight(.bold)).lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right").foregroundStyle(RepoFeedTheme.muted)
                }
                Text(artifact.displayTask.replacingOccurrences(of: "-", with: " ").capitalized)
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.82))
                HStack(spacing: 11) {
                    Label(compactCount(artifact.downloads), systemImage: "arrow.down")
                    Label(compactCount(artifact.likes), systemImage: "heart.fill")
                    Spacer()
                    Text(artifact.licenseID?.uppercased() ?? "OSS")
                        .foregroundStyle(RepoFeedTheme.secondary)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RepoFeedTheme.muted)
            }
            .padding(15)
            .frame(maxWidth: .infinity, minHeight: 145, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .repoCard(elevated: true)
    }
}

struct HubMark: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xFFD21E), Color(hex: 0xFF9D00)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: "face.smiling")
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.75))
        }
        .frame(width: size, height: size)
    }
}

struct RemoteRepositoryCard: View {
    let repository: GitHubRepository
    @ObservedObject var model: AppModel
    var compact = false
    var benefitReason: String? = nil

    var body: some View {
        Button { model.open(repository.htmlURL) } label: {
            VStack(alignment: .leading, spacing: compact ? 11 : 14) {
                HStack(spacing: 10) {
                    RepoMark(seed: repository.fullName, size: compact ? 36 : 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(repository.owner.login)
                            .font(.caption)
                            .foregroundStyle(RepoFeedTheme.muted)
                        Text(repository.name)
                            .font(.headline.weight(.bold))
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RepoFeedTheme.muted)
                }

                Text(repository.description ?? "A public repository on GitHub.")
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(Color.white.opacity(0.78))
                    .lineLimit(compact ? 3 : 4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let benefitReason {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("WHY IT MAY HELP")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.1)
                            .foregroundStyle(RepoFeedTheme.primary)
                        Text(benefitReason)
                            .font(.caption2)
                            .foregroundStyle(RepoFeedTheme.muted)
                            .lineLimit(compact ? 3 : 4)
                    }
                    .padding(10)
                    .background(RepoFeedTheme.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }

                HStack(spacing: 12) {
                    Label(compactCount(repository.stars), systemImage: "star.fill")
                    if let language = repository.language {
                        Label(language, systemImage: "circle.fill")
                    }
                    Spacer()
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(RepoFeedTheme.muted)
            }
            .padding(compact ? 15 : 18)
            .frame(maxWidth: .infinity, minHeight: compact ? (benefitReason == nil ? 150 : 220) : (benefitReason == nil ? 180 : 260), alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .repoCard(elevated: true)
    }
}

struct RecommendedStrip: View {
    let repositories: [GitHubRepository]
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(eyebrow: "Recommended", title: "Repos that could benefit you", trailing: "from your private profile")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(repositories) { repository in
                        RemoteRepositoryCard(
                            repository: repository,
                            model: model,
                            compact: true,
                            benefitReason: model.recommendationReason(for: repository)
                        )
                        .frame(width: 310)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
