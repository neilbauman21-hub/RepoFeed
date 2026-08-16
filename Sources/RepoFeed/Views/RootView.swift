import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            AppTopBar(model: model)
            Divider().overlay(RepoFeedTheme.border)
            NavigationSplitView {
                SidebarView(model: model)
                    .navigationSplitViewColumnWidth(min: 220, ideal: 244, max: 280)
            } detail: {
                Group {
                    switch model.destination {
                    case .feed:
                        FeedView(model: model)
                    case .library:
                        LibraryView(model: model)
                    case .discover:
                        DiscoverView(model: model)
                    case .permissions:
                        PermissionsView(model: model)
                    }
                }
                .background(RepoFeedTheme.background)
            }
            .navigationSplitViewStyle(.balanced)
        }
        .background(RepoFeedTheme.sidebar)
        .alert("RepoFeed", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "Something went wrong.")
        }
    }
}

private struct AppTopBar: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(RepoFeedTheme.primary)
                Text("r")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: -1)
            }
            .frame(width: 40, height: 40)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(RepoFeedTheme.muted)
                TextField("Search your projects", text: $model.searchText)
                    .textFieldStyle(.plain)
                    .onSubmit { model.destination = .library }
            }
            .padding(.horizontal, 13)
            .frame(width: 265, height: 40)
            .background(Color(hex: 0x3A3B3C), in: Capsule())

            Spacer(minLength: 16)
            HStack(spacing: 4) {
                TopNavigationButton(destination: .feed, model: model)
                TopNavigationButton(destination: .discover, model: model)
                TopNavigationButton(destination: .library, model: model)
            }
            Spacer(minLength: 16)

            Button { model.requestRefresh() } label: {
                Group {
                    if model.isRefreshing { ProgressView().controlSize(.small) }
                    else { Image(systemName: "arrow.clockwise") }
                }
                .frame(width: 38, height: 38)
                .background(Color(hex: 0x3A3B3C), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(model.isRefreshing)
            .help("Refresh your profile")

            Button { model.chooseFolders() } label: {
                Image(systemName: "plus")
                    .font(.headline)
                    .frame(width: 38, height: 38)
                    .background(Color(hex: 0x3A3B3C), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Allow another folder")

            Button { model.destination = .permissions } label: {
                ZStack {
                    Circle().fill(LinearGradient(colors: [RepoFeedTheme.primary, RepoFeedTheme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "person.fill").foregroundStyle(.white)
                }
                .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .help("Profile and permissions")
        }
        .padding(.leading, 82)
        .padding(.trailing, 16)
        .frame(height: 58)
        .background(RepoFeedTheme.sidebar)
    }
}

private struct TopNavigationButton: View {
    let destination: FeedDestination
    @ObservedObject var model: AppModel

    var body: some View {
        Button { model.destination = destination } label: {
            VStack(spacing: 8) {
                Image(systemName: destination.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(model.destination == destination ? RepoFeedTheme.primary : RepoFeedTheme.muted)
                Rectangle()
                    .fill(model.destination == destination ? RepoFeedTheme.primary : .clear)
                    .frame(height: 3)
                    .clipShape(Capsule())
            }
            .frame(width: 104, height: 55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(destination.rawValue)
    }
}

private struct SidebarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [RepoFeedTheme.primary, RepoFeedTheme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "person.fill").foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Your builder profile")
                        .font(.headline.weight(.bold))
                    Text(model.builderProfile.technologies.prefix(2).map(\.name).joined(separator: " · ").isEmpty ? "Private and on-device" : model.builderProfile.technologies.prefix(2).map(\.name).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(RepoFeedTheme.muted)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 18)

            List(FeedDestination.allCases, selection: $model.destination) { destination in
                Label(destination.rawValue, systemImage: destination.icon)
                    .font(.body.weight(.medium))
                    .padding(.vertical, 5)
                    .tag(destination)
            }
            .scrollContentBackground(.hidden)
            .listStyle(.sidebar)

            VStack(alignment: .leading, spacing: 12) {
                Divider().overlay(RepoFeedTheme.border)
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(RepoFeedTheme.primary)
                    Text("Local by default")
                        .font(.caption.weight(.semibold))
                }
                Text(model.statusMessage)
                    .font(.caption)
                    .foregroundStyle(RepoFeedTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                if model.isRefreshing {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .tint(RepoFeedTheme.primary)
                }
            }
            .padding(18)
        }
        .background(RepoFeedTheme.sidebar)
    }
}
