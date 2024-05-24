import SwiftUI

@main
struct SiestaExtSimpleExampleApp: App {
    var body: some Scene {
        WindowGroup {
            PostsView()
            .environmentObject(APIClient())
        }
    }
}
