import SwiftUI

struct PermissionsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading(eyebrow: "Privacy", title: "You control what RepoFeed can see")

                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(RepoFeedTheme.primary)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Folder-scoped, read-only access")
                            .font(.headline)
                        Text("RepoFeed inventories files only inside folders you explicitly select, then reads a diverse rotating sample of safe code, docs, and configs on your Mac. It always excludes secrets, keys, credentials, dependency folders, build output, system libraries, and personal media libraries. GitHub receives short profile terms—not your files, paths, or file contents.")
                            .foregroundStyle(RepoFeedTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(22)
                .repoCard(elevated: true)

                VStack(alignment: .leading, spacing: 14) {
                    Label("No-server architecture", systemImage: "network.slash")
                        .font(.headline)
                        .foregroundStyle(RepoFeedTheme.secondary)
                    HStack(alignment: .top, spacing: 20) {
                        ArchitecturePoint(icon: "desktopcomputer", title: "One person, one Mac", detail: "No accounts, profiles, followers, or inter-user features.")
                        ArchitecturePoint(icon: "externaldrive.fill", title: "Local state only", detail: "The profile, samples, permissions, and caches stay on this device.")
                        ArchitecturePoint(icon: "checkmark.seal.fill", title: "OSS-only discovery", detail: "Results require an explicit approved open-source license.")
                    }
                    Text("RepoFeed has no backend, hosted database, analytics endpoint, or telemetry. It contacts GitHub and Hugging Face directly for public metadata only.")
                        .font(.caption)
                        .foregroundStyle(RepoFeedTheme.muted)
                }
                .padding(22)
                .repoCard()

                HStack {
                    Text("Allowed folders")
                        .font(.title3.weight(.bold))
                    Spacer()
                    Button("Add Folder", systemImage: "plus") { model.chooseFolders() }
                        .buttonStyle(.bordered)
                }

                if model.allowedFolders.isEmpty {
                    ContentUnavailableView(
                        "No folder access",
                        systemImage: "folder.badge.questionmark",
                        description: Text("Choose a folder to start building your feed.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 260)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(model.allowedFolders.enumerated()), id: \.element.id) { index, folder in
                            HStack(spacing: 14) {
                                Image(systemName: "folder.fill")
                                    .font(.title2)
                                    .foregroundStyle(RepoFeedTheme.secondary)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(folder.displayName).font(.headline)
                                    Text(folder.displayPath)
                                        .font(.caption)
                                        .foregroundStyle(RepoFeedTheme.muted)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                Button("Remove", role: .destructive) { model.removeFolder(folder) }
                                    .buttonStyle(.bordered)
                            }
                            .padding(18)
                            if index < model.allowedFolders.count - 1 {
                                Divider().overlay(RepoFeedTheme.border)
                            }
                        }
                    }
                    .repoCard()
                }

                Text("Removing a folder deletes RepoFeed’s saved permission and refreshes the private profile. RepoFeed never deletes or changes anything inside allowed folders.")
                    .font(.caption)
                    .foregroundStyle(RepoFeedTheme.muted)
            }
            .padding(30)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(RepoFeedTheme.background)
    }
}

private struct ArchitecturePoint: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon).font(.title3).foregroundStyle(RepoFeedTheme.primary)
            Text(title).font(.subheadline.weight(.bold))
            Text(detail).font(.caption).foregroundStyle(RepoFeedTheme.muted).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
