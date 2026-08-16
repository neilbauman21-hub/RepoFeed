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
                        Label("On this Mac", systemImage: "laptopcomputer")
                        Text("·")
                        Text(repository.modifiedAt, style: .relative)
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
