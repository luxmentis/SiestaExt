import SwiftUI
import Foundation

@main
struct GithubBrowserApp: App {
    init() {
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
