import SwiftUI

#if canImport(Sparkle)
import Sparkle

private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    func feedURLString(for updater: SPUUpdater) -> String? {
        "https://raw.githubusercontent.com/wieandteduard/port-menu/main/packaging/appcast.xml"
    }
}
#endif

@main
struct PorterApp: App {
    @State private var store = PortStore.shared
    @AppStorage("hideMenuBarWhenEmpty") private var hideMenuBarWhenEmpty = false

    #if canImport(Sparkle)
    private let updaterController: SPUStandardUpdaterController
    private let updaterDelegate = UpdaterDelegate()
    #endif

    init() {
        #if canImport(Sparkle)
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: updaterDelegate,
            userDriverDelegate: nil
        )
        #endif

        moveToApplicationsIfNeeded()
        Task { @MainActor in
            PortStore.shared.ensurePolling()
        }
    }

    var body: some Scene {
        MenuBarExtra(isInserted: isMenuBarExtraInserted) {
            PortListView(updater: updater)
                .environment(store)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: store.entries.isEmpty
                      ? "square.fill"
                      : "circle.fill")
                    .font(.system(size: 5.5))
                    .foregroundStyle(statusColor)
                Text(store.entries.count, format: .number)
                    .fontDesign(.monospaced)
            }
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updater)
            }
        }
    }

    private var updater: (any AppUpdateChecking)? {
        #if canImport(Sparkle)
        updaterController.updater
        #else
        nil
        #endif
    }

    private var isMenuBarExtraInserted: Binding<Bool> {
        Binding(
            get: { hideMenuBarWhenEmpty ? !store.entries.isEmpty : true },
            set: { _ in }
        )
    }

    private var statusColor: Color {
        if store.lastError != nil && store.entries.isEmpty {
            return .orange
        }
        return store.entries.isEmpty ? .gray : .green
    }
}
