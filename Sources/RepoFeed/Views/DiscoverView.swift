import SwiftUI

struct DiscoverView: View {
    @ObservedObject var model: AppModel
    private let columns = [GridItem(.adaptive(minimum: 270, maximum: 390), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 34) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(eyebrow: "Personalized", title: model.builderProfile.headline)
                    if model.interestProfile.isEmpty {
                        Text("Add a folder to create your local interest profile.")
                            .foregroundStyle(RepoFeedTheme.muted)
                    } else {
                        HStack(spacing: 8) {
                            ForEach(model.interestProfile, id: \.self) { TopicPill(text: $0) }
                        }
                    }
                }

                if !model.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeading(eyebrow: "For you", title: "Repositories that fill useful gaps", trailing: "public GitHub results")
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(model.recommendations) {
                                RemoteRepositoryCard(
                                    repository: $0,
                                    model: model,
                                    benefitReason: model.recommendationReason(for: $0)
                                )
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    SectionHeading(eyebrow: "Fresh", title: "Trending repositories", trailing: "created in the last 45 days")
                    if model.trendingRepositories.isEmpty {
                        ProgressView().tint(RepoFeedTheme.primary).frame(maxWidth: .infinity).padding(50)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(model.trendingRepositories) {
                                RemoteRepositoryCard(repository: $0, model: model)
                            }
                        }
                    }
                }
            }
            .padding(30)
        }
        .background(RepoFeedTheme.background)
    }
}
