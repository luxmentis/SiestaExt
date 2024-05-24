import SwiftUI
import Foundation
import Siesta

@main
struct GithubBrowserApp: App {
    init() {
        SiestaLog.Category.enabled = .detailed

        if let pat = ProcessInfo.processInfo.environment["personalAccessToken"] {
            GitHubAPI.logIn(personalAccessToken: pat)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
