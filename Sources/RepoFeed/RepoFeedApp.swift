import SwiftUI

@main
struct RepoFeedApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .frame(minWidth: 1_080, minHeight: 720)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1_280, height: 820)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Add Folder…") { model.chooseFolders() }
                    .keyboardShortcut("o", modifiers: [.command])
                Button("Refresh Feed") { model.requestRefresh() }
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }
}
