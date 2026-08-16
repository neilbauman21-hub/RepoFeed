import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel

    var body: some View {
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
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if model.destination == .library {
                        TextField("Search repositories", text: $model.searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 230)
                    }
                    Button {
                        model.requestRefresh()
                    } label: {
                        if model.isRefreshing {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .help("Refresh feed")
                    .disabled(model.isRefreshing)

                    Button("Add Folder", systemImage: "folder.badge.plus") {
                        model.chooseFolders()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(RepoFeedTheme.primary)
                    .foregroundStyle(.black)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
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

private struct SidebarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [RepoFeedTheme.primary, RepoFeedTheme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black.opacity(0.75))
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 1) {
                    Text("RepoFeed")
                        .font(.title3.weight(.bold))
                    Text("Your code, rediscovered")
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
