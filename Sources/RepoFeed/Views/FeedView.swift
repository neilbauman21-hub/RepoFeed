import SwiftUI

struct FeedView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        GeometryReader { proxy in
            if model.allowedFolders.isEmpty {
                OnboardingView(model: model)
            } else {
                HStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 18) {
                            FeedHeader(model: model)

                            ScanComposer(model: model)

                            if model.builderProfile.scannedFileCount > 0 || !model.builderProfile.technologies.isEmpty {
                                if !model.builderProfile.opportunities.isEmpty {
                                    OpportunityStories(profile: model.builderProfile)
                                }
                                BuilderProfileCard(profile: model.builderProfile)
                            }

                            if model.discoveryMode == .github && !model.recommendations.isEmpty {
                                SectionHeading(eyebrow: "Suggested for you", title: "Tools your profile could use", trailing: "personalized")
                                    .padding(.top, 8)
                                ForEach(model.recommendations.prefix(3)) { repository in
                                    SuggestedRepositoryPost(repository: repository, model: model)
                                }
                            } else if model.discoveryMode == .huggingFace && !model.huggingFaceRecommendations.isEmpty {
                                SectionHeading(eyebrow: "Open source AI", title: "Models and datasets for your work", trailing: "explicit licenses only")
                                    .padding(.top, 8)
                                ForEach(model.huggingFaceRecommendations.prefix(4)) { artifact in
                                    HuggingFaceArtifactPost(artifact: artifact, model: model)
                                }
                            }

                            if model.localRepositories.isEmpty && model.isRefreshing {
                                loadingCard
                            } else if model.localRepositories.isEmpty {
                                emptyCard
                            } else {
                                SectionHeading(eyebrow: "Your Mac", title: "Projects behind the profile", trailing: "README view")
                                    .padding(.top, 10)
                                ForEach(model.localRepositories.prefix(20)) { repository in
                                    LocalRepositoryCard(repository: repository, model: model)
                                }
                            }
                        }
                        .padding(28)
                        .frame(maxWidth: 720)
                        .frame(maxWidth: .infinity)
                    }

                    if proxy.size.width > 900 {
                        Divider().overlay(RepoFeedTheme.border)
                        Group {
                            if model.discoveryMode == .github {
                                TrendingRail(model: model)
                            } else {
                                HuggingFaceTrendingRail(model: model)
                            }
                        }
                            .frame(width: min(350, proxy.size.width * 0.31))
                    }
                }
            }
        }
        .background(RepoFeedTheme.background)
    }

    private var loadingCard: some View {
        HStack(spacing: 14) {
            ProgressView().controlSize(.small).tint(RepoFeedTheme.primary)
            Text("Inventorying safe files and sampling a varied mix of code, docs, and configs…")
                .foregroundStyle(RepoFeedTheme.muted)
            Spacer()
        }
        .padding(22)
        .repoCard()
    }

    private var emptyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(RepoFeedTheme.secondary)
            Text("No repositories found")
                .font(.headline)
            Text("RepoFeed looks for README files next to a .git folder or a common project manifest.")
                .font(.subheadline)
                .foregroundStyle(RepoFeedTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(36)
        .repoCard()
    }
}

private struct FeedHeader: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("REPOFEED")
                        .font(.caption2.weight(.bold))
                        .tracking(1.8)
                        .foregroundStyle(RepoFeedTheme.primary)
                    Text("Home")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                Spacer()
                Label("Only you", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RepoFeedTheme.muted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05), in: Capsule())
            }
            DiscoveryModePicker(model: model)
            if !model.interestProfile.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        Text("Profiled from")
                            .font(.caption)
                            .foregroundStyle(RepoFeedTheme.muted)
                        ForEach(model.interestProfile.prefix(6), id: \.self) { TopicPill(text: $0) }
                    }
                }
            }
        }
        .padding(.bottom, 2)
    }
}

private struct OnboardingView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                Spacer(minLength: 54)
                ZStack {
                    Circle().fill(RepoFeedTheme.primary.opacity(0.09)).frame(width: 180, height: 180)
                    Circle().fill(RepoFeedTheme.secondary.opacity(0.12)).frame(width: 128, height: 128).offset(x: 34, y: -22)
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(LinearGradient(colors: [RepoFeedTheme.primary, RepoFeedTheme.secondary], startPoint: .top, endPoint: .bottom))
                }
                VStack(spacing: 10) {
                    Text("Build a profile from your work")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("Choose any folders you want RepoFeed to understand. It inventories safe files, samples a varied mix of code, docs, and configs locally, then recommends public repos that could improve how you work.")
                        .font(.title3)
                        .foregroundStyle(RepoFeedTheme.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 660)
                }
                Button {
                    model.chooseFolders()
                } label: {
                    Label("Choose folders", systemImage: "folder.badge.plus")
                        .font(.headline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(RepoFeedTheme.primary)
                .foregroundStyle(.black)

                HStack(spacing: 26) {
                    PrivacyPoint(icon: "hand.raised.fill", text: "You choose every folder")
                    PrivacyPoint(icon: "internaldrive.fill", text: "File analysis stays local")
                    PrivacyPoint(icon: "arrow.up.right.square.fill", text: "Direct public API searches")
                }
                .padding(.top, 10)

                DiscoveryModePicker(model: model)

                if model.discoveryMode == .github && !model.trendingRepositories.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeading(eyebrow: "While you decide", title: "Fresh on GitHub")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                            ForEach(model.trendingRepositories.prefix(3)) {
                                RemoteRepositoryCard(repository: $0, model: model, compact: true)
                            }
                        }
                    }
                    .frame(maxWidth: 900)
                    .padding(.top, 32)
                } else if model.discoveryMode == .huggingFace && !model.huggingFaceTrending.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeading(eyebrow: "While you decide", title: "Open on Hugging Face")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                            ForEach(model.huggingFaceTrending.prefix(3)) {
                                HuggingFaceArtifactCard(artifact: $0, model: model)
                            }
                        }
                    }
                    .frame(maxWidth: 900)
                    .padding(.top, 32)
                }
                Spacer(minLength: 40)
            }
            .padding(40)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct HuggingFaceTrendingRail: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeading(eyebrow: "Hugging Face", title: "Trending OSS", trailing: "licensed only")
                if model.huggingFaceTrending.isEmpty {
                    ProgressView().tint(RepoFeedTheme.primary).frame(maxWidth: .infinity).padding(30)
                } else {
                    ForEach(Array(model.huggingFaceTrending.prefix(6).enumerated()), id: \.element.id) { index, artifact in
                        Button { model.open(artifact.url) } label: {
                            HStack(spacing: 11) {
                                Text(String(format: "%02d", index + 1))
                                    .font(.caption.monospacedDigit().weight(.bold))
                                    .foregroundStyle(index < 3 ? RepoFeedTheme.primary : RepoFeedTheme.muted)
                                    .frame(width: 24)
                                HubMark(size: 36)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(artifact.id).font(.subheadline.weight(.semibold)).lineLimit(1)
                                    Text("\(artifact.kind.rawValue) · \(artifact.licenseID?.uppercased() ?? "OSS")")
                                        .font(.caption2).foregroundStyle(RepoFeedTheme.muted)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(RepoFeedTheme.muted)
                            }
                            .padding(11)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                Divider().overlay(RepoFeedTheme.border)
                Label("Direct API · no RepoFeed server", systemImage: "lock.shield.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RepoFeedTheme.secondary)
                Text("Private and gated artifacts, missing licenses, and non-commercial licenses are excluded.")
                    .font(.caption)
                    .foregroundStyle(RepoFeedTheme.muted)
            }
            .padding(24)
        }
        .background(RepoFeedTheme.sidebar.opacity(0.58))
    }
}

private struct PrivacyPoint: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(RepoFeedTheme.primary)
            Text(text).font(.caption).foregroundStyle(RepoFeedTheme.muted)
        }
    }
}

private struct TrendingRail: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeading(eyebrow: "GitHub", title: "Trending now", trailing: "last 45 days")
                if model.trendingRepositories.isEmpty {
                    ProgressView().tint(RepoFeedTheme.primary).frame(maxWidth: .infinity).padding(30)
                } else {
                    ForEach(Array(model.trendingRepositories.prefix(6).enumerated()), id: \.element.id) { index, repo in
                        TrendingRow(rank: index + 1, repository: repo, model: model)
                    }
                }
                Divider().overlay(RepoFeedTheme.border).padding(.vertical, 4)
                VStack(alignment: .leading, spacing: 8) {
                    Label("How this works", systemImage: "info.circle.fill")
                        .font(.subheadline.weight(.semibold))
                    Text("Trending highlights recently created public repositories with strong star growth. Recommendations are ranked against your private builder profile and improvement opportunities.")
                        .font(.caption)
                        .foregroundStyle(RepoFeedTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .repoCard()
            }
            .padding(24)
        }
        .background(RepoFeedTheme.sidebar.opacity(0.58))
    }
}

private struct TrendingRow: View {
    let rank: Int
    let repository: GitHubRepository
    @ObservedObject var model: AppModel

    var body: some View {
        Button { model.open(repository.htmlURL) } label: {
            HStack(spacing: 11) {
                Text(String(format: "%02d", rank))
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(rank <= 3 ? RepoFeedTheme.primary : RepoFeedTheme.muted)
                    .frame(width: 24)
                RepoMark(seed: repository.fullName, size: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(repository.fullName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                        Text(compactCount(repository.stars))
                        if let language = repository.language {
                            Text("· \(language)")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(RepoFeedTheme.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(RepoFeedTheme.muted)
            }
            .padding(11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
