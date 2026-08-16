import SwiftUI

struct ScanComposer: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [RepoFeedTheme.primary, RepoFeedTheme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "person.fill").foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)

                Button { model.chooseFolders() } label: {
                    Text("What should RepoFeed learn from?")
                        .foregroundStyle(RepoFeedTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .frame(height: 42)
                        .background(Color(hex: 0x3A3B3C), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Divider().overlay(RepoFeedTheme.border)

            HStack(spacing: 0) {
                ComposerAction(title: "Add folder", icon: "folder.fill", color: Color(hex: 0x45BD62)) {
                    model.chooseFolders()
                }
                ComposerAction(title: "Scan again", icon: "arrow.triangle.2.circlepath", color: RepoFeedTheme.primary) {
                    model.requestRefresh()
                }
                ComposerAction(title: "Privacy", icon: "lock.shield.fill", color: Color(hex: 0xF7B928)) {
                    model.destination = .permissions
                }
            }
        }
        .padding(14)
        .repoCard()
    }
}

private struct ComposerAction: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).foregroundStyle(RepoFeedTheme.muted)
            }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .tint(color)
        .overlay(alignment: .leading) {
            if title != "Add folder" {
                Rectangle().fill(RepoFeedTheme.border).frame(width: 1, height: 24)
            }
        }
    }
}

struct OpportunityStories: View {
    let profile: BuilderProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Opportunities for you")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("From your profile")
                    .font(.caption)
                    .foregroundStyle(RepoFeedTheme.primary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(profile.opportunities.prefix(4).enumerated()), id: \.element.id) { index, opportunity in
                        OpportunityStory(opportunity: opportunity, index: index)
                    }
                }
            }
        }
    }
}

private struct OpportunityStory: View {
    let opportunity: BuilderProfile.Opportunity
    let index: Int

    private var gradient: [Color] {
        let options: [[Color]] = [
            [Color(hex: 0x1877F2), Color(hex: 0x084C9E)],
            [Color(hex: 0x45BD62), Color(hex: 0x18753A)],
            [Color(hex: 0xA970FF), Color(hex: 0x5E2F98)],
            [Color(hex: 0xF5533D), Color(hex: 0x9F2316)]
        ]
        return options[index % options.count]
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .fill(.white.opacity(0.15))
                .frame(width: 100, height: 100)
                .offset(x: 66, y: -76)
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Circle().fill(.white.opacity(0.2))
                    Image(systemName: "sparkles").font(.headline)
                }
                .frame(width: 36, height: 36)
                Spacer()
                Text(opportunity.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
            }
            .padding(13)
        }
        .frame(width: 150, height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }
}
