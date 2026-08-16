import Foundation

@MainActor
final class FolderAccessStore {
    private let defaultsKey = "repofeed.allowed-folders.v1"
    private let defaults: UserDefaults

    private(set) var folders: [AllowedFolder]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([AllowedFolder].self, from: data) {
            folders = decoded
        } else {
            folders = []
        }
    }

    @discardableResult
    func add(_ urls: [URL]) throws -> [AllowedFolder] {
        var added: [AllowedFolder] = []
        for url in urls where !folders.contains(where: { $0.displayPath == url.path }) {
            let bookmark = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: [.nameKey],
                relativeTo: nil
            )
            let folder = AllowedFolder(
                id: UUID(),
                displayName: url.lastPathComponent,
                displayPath: url.path,
                bookmark: bookmark
            )
            folders.append(folder)
            added.append(folder)
        }
        save()
        return added
    }

    func remove(id: UUID) {
        folders.removeAll { $0.id == id }
        save()
    }

    func resolveFolders() -> [URL] {
        var resolved: [URL] = []
        var updatedFolders = folders

        for index in updatedFolders.indices {
            var isStale = false
            guard let url = try? URL(
                resolvingBookmarkData: updatedFolders[index].bookmark,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) else { continue }

            if isStale, let refreshed = try? url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: [.nameKey],
                relativeTo: nil
            ) {
                updatedFolders[index].bookmark = refreshed
            }
            updatedFolders[index].displayName = url.lastPathComponent
            updatedFolders[index].displayPath = url.path
            resolved.append(url)
        }
        folders = updatedFolders
        save()
        return resolved
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(folders) else { return }
        defaults.set(data, forKey: defaultsKey)
    }
}
