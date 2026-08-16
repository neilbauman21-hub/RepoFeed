import SwiftUI

struct BuilderProfileCard: View {
    let profile: BuilderProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color(hex: 0x1877F2), Color(hex: 0x3B5998), Color(hex: 0x242526)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .font(.system(size: 72, weight: .thin))
                        .foregroundStyle(.white.opacity(0.18))
                        .padding(18)
                }
                .frame(height: 122)

                ZStack {
                    Circle().fill(LinearGradient(colors: [RepoFeedTheme.primary, RepoFeedTheme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "person.fill")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(.white)
                }
                .frame(width: 78, height: 78)
                .overlay { Circle().stroke(RepoFeedTheme.card, lineWidth: 5) }
                .offset(x: 20, y: 34)
            }

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Builder Profile")
                        .font(.title2.weight(.bold))
                    Text(profile.headline)
                        .font(.subheadline)
                        .foregroundStyle(RepoFeedTheme.muted)
                }

                HStack(spacing: 0) {
                    ProfileMetric(value: compactCount(profile.scannedFileCount), label: "Files")
                    ProfileMetric(value: compactCount(profile.sampledFileCount), label: "Sampled")
                    ProfileMetric(value: String(profile.repositoryCount), label: "Projects")
                }
                .padding(.vertical, 4)
                .background(Color(hex: 0x3A3B3C), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                if !profile.technologies.isEmpty {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Text("About")
                                .font(.headline.weight(.bold))
                            Spacer()
                            Label("Only you", systemImage: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(RepoFeedTheme.muted)
                        }
                        HStack(spacing: 7) {
                            ForEach(profile.technologies.prefix(6)) { technology in
                                TopicPill(text: technology.name, tint: RepoFeedTheme.primary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 44)
            .padding(.bottom, 20)
        }
        .background(RepoFeedTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(RepoFeedTheme.border, lineWidth: 1)
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
