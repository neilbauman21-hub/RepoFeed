import SwiftUI

struct LibraryView: View {
    @ObservedObject var model: AppModel
    private let columns = [GridItem(.adaptive(minimum: 350, maximum: 520), spacing: 18)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeading(
                    eyebrow: "On this Mac",
                    title: "Local Library",
                    trailing: "\(model.visibleLocalRepositories.count) repositories"
                )

                if model.visibleLocalRepositories.isEmpty {
                    ContentUnavailableView(
                        model.searchText.isEmpty ? "No local repositories" : "No matches",
                        systemImage: "books.vertical",
                        description: Text(model.searchText.isEmpty ? "Add a folder containing repositories with README files." : "Try a different title, topic, or technology.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 420)
                } else {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(model.visibleLocalRepositories) { repository in
                            LocalRepositoryCard(repository: repository, model: model)
                        }
                    }
                }
            }
            .padding(30)
        }
        .background(RepoFeedTheme.background)
    }
}
