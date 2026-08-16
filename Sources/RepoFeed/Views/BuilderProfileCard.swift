import SwiftUI

struct BuilderProfileCard: View {
    let profile: BuilderProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle().fill(RepoFeedTheme.primary.opacity(0.14))
                    Image(systemName: "person.crop.circle.dashed.circle")
                        .font(.system(size: 29, weight: .medium))
                        .foregroundStyle(RepoFeedTheme.primary)
                }
                .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR PRIVATE BUILDER PROFILE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.35)
                        .foregroundStyle(RepoFeedTheme.primary)
                    Text(profile.headline)
                        .font(.title3.weight(.bold))
                }
                Spacer()
                Label("On-device", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RepoFeedTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RepoFeedTheme.primary.opacity(0.09), in: Capsule())
            }

            HStack(spacing: 0) {
                ProfileMetric(value: compactCount(profile.scannedFileCount), label: "inventoried")
                ProfileMetric(value: compactCount(profile.sampledFileCount), label: "sampled")
                ProfileMetric(value: String(profile.repositoryCount), label: "repositories")
            }
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if !profile.technologies.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    Text("Strongest signals")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RepoFeedTheme.muted)
                    HStack(spacing: 7) {
                        ForEach(profile.technologies.prefix(6)) { technology in
                            TopicPill(text: technology.name, tint: RepoFeedTheme.primary)
                        }
                    }
                }
            }

            if !profile.opportunities.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("What could benefit you")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RepoFeedTheme.muted)
                    ForEach(profile.opportunities.prefix(3)) { opportunity in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "sparkle")
                                .foregroundStyle(RepoFeedTheme.secondary)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(opportunity.title).font(.subheadline.weight(.semibold))
                                Text(opportunity.reason)
                                    .font(.caption)
                                    .foregroundStyle(RepoFeedTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
        .padding(22)
        .background {
            ZStack {
                RepoFeedTheme.card
                LinearGradient(
                    colors: [RepoFeedTheme.primary.opacity(0.07), RepoFeedTheme.secondary.opacity(0.025), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(RepoFeedTheme.primary.opacity(0.19), lineWidth: 1)
        }
    }
}

private struct ProfileMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(RepoFeedTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
    }
}
